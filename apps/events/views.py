import json

from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.utils import timezone
from django.utils.dateparse import parse_datetime
from django.db.models import Count, Q
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Event, EventQuestion, EventRegistration
from .forms import EventForm, EventQuestionForm
from django.forms import modelformset_factory
from apps.tests.models import Category
from apps.users.views import token_required

@login_required
def recruiter_dashboard(request):
    if not request.user.is_company:
        return redirect('home')
    
    events = Event.objects.filter(recruiter=request.user).order_by('-created_at')
    return render(request, 'events/recruiter_dashboard.html', {'events': events})

@login_required
def create_event(request):
    if not request.user.is_company:
        return redirect('home')

    if request.method == 'POST':
        form = EventForm(request.POST)
        if form.is_valid():
            event = form.save(commit=False)
            event.recruiter = request.user
            event.save()
            messages.success(request, 'Event created! Now add some questions.')
            return redirect('add_questions', event_id=event.id)
    else:
        form = EventForm()
    
    return render(request, 'events/create_event.html', {'form': form})

@login_required
def add_questions(request, event_id):
    if not request.user.is_company:
        return redirect('home')
        
    event = get_object_or_404(Event, id=event_id, recruiter=request.user)
    
    if request.method == 'POST':
        form = EventQuestionForm(request.POST)
        if form.is_valid():
            question = form.save(commit=False)
            question.event = event
            question.save()
            messages.success(request, 'Question added successfully.')
            
            if 'save_and_add_another' in request.POST:
                return redirect('add_questions', event_id=event.id)
            else:
                return redirect('recruiter_events')
    else:
        form = EventQuestionForm()
    
    existing_questions = event.questions.all()
    
    return render(request, 'events/add_questions.html', {
        'form': form,
        'event': event,
        'existing_questions': existing_questions
    })

@login_required
def cancel_event(request, event_id):
    if not request.user.is_company:
        return redirect('home')
        
    event = get_object_or_404(Event, id=event_id, recruiter=request.user)
    
    if event.is_live:
         messages.error(request, "Cannot cancel a live event.")
    else:
        event.delete()
        messages.success(request, "Event cancelled successfully.")
        
    return redirect('recruiter_events')

@login_required
def event_results(request, event_id):
    if not request.user.is_company:
        return redirect('home')
        
    event = get_object_or_404(Event, id=event_id, recruiter=request.user)
    registrations = EventRegistration.objects.filter(event=event).select_related('user').order_by('-score', 'completed_at')
    
    return render(request, 'events/event_results.html', {
        'event': event,
        'registrations': registrations
    })

# Student Views

@login_required
def event_list(request):
    now = timezone.now()
    # Events that are upcoming or currently live
    events = Event.objects.filter(is_active=True, end_time__gt=now).order_by('start_time')
    
    return render(request, 'events/event_list.html', {'events': events})

@login_required
def event_detail(request, event_id):
    event = get_object_or_404(Event, id=event_id)
    
    # Check if already registered
    registration = EventRegistration.objects.filter(user=request.user, event=event).first()
    is_registered = registration is not None
    
    if request.method == 'POST' and 'register' in request.POST:
        if not is_registered:
            # Check threshold
            if event.threshold_type == 'LEVEL':
               if request.user.level < event.threshold_value:
                   messages.error(request, f"You need to be at least level {event.threshold_value} to enter.")
                   return redirect('event_detail', event_id=event.id)
            elif event.threshold_type == 'TIME':
                # TIME = First Come First Serve = Max Participants
                current_registrations = EventRegistration.objects.filter(event=event).count()
                if event.threshold_value > 0 and current_registrations >= event.threshold_value:
                    messages.error(request, "Event is full. Max participants reached.")
                    return redirect('event_detail', event_id=event.id)
            
            # Life Deduction
            if not request.user.is_company and not request.user.is_superuser:
                if request.user.lives > 0:
                    request.user.lives -= 1
                    request.user.save()
                else:
                    messages.error(request, "You don't have enough lives to enter this event. Purchase more in the store.")
                    return redirect('store')
            
            EventRegistration.objects.create(user=request.user, event=event)
            messages.success(request, "Successfully registered for the event!")
            return redirect('event_detail', event_id=event.id)

    return render(request, 'events/event_detail.html', {
        'event': event, 
        'is_registered': is_registered,
        'registration': registration,
        'now': timezone.now()
    })

@login_required
def take_event(request, event_id):
    event = get_object_or_404(Event, id=event_id)
    # Ensure registration exists
    registration = get_object_or_404(EventRegistration, user=request.user, event=event)
    
    if not event.is_live:
         messages.error(request, "This event is not currently live.")
         return redirect('event_detail', event_id=event.id)
    
    if registration.completed_at:
        messages.info(request, "You have already completed this event.")
        return redirect('event_detail', event_id=event.id)

    if request.method == 'POST':
        score = 0
        questions = event.questions.all()[:event.total_questions]
        for q in questions:
            selected_option = request.POST.get(f'question_{q.id}')
            if selected_option and selected_option == q.correct_option:
                score += q.marks
        
        registration.score = score
        registration.completed_at = timezone.now()
        registration.save()
        
        messages.success(request, f"Event completed! You scored {score}.")
        return redirect('event_detail', event_id=event.id)

    questions = event.questions.all()[:event.total_questions]
    return render(request, 'events/take_event.html', {'event': event, 'questions': questions})


@csrf_exempt
@token_required
def api_recruiter_events(request):
    if request.method != 'GET':
        return JsonResponse({'error': 'Only GET requests are allowed.'}, status=405)

    if not request.user.is_company:
        return JsonResponse({'error': 'Only recruiter accounts may access this endpoint.'}, status=403)

    events = Event.objects.filter(recruiter=request.user).order_by('-created_at')
    data = []
    for event in events:
        data.append({
            'id': event.id,
            'title': event.title,
            'description': event.description,
            'category': {
                'id': event.category.id if event.category else None,
                'name': event.category.name if event.category else None,
            } if event.category else None,
            'start_time': event.start_time.isoformat(),
            'end_time': event.end_time.isoformat(),
            'total_questions': event.total_questions,
            'time_limit_seconds': event.time_limit_seconds,
            'threshold_type': event.threshold_type,
            'threshold_value': event.threshold_value,
            'is_active': event.is_active,
            'created_at': event.created_at.isoformat(),
            'registrations_count': event.registrations.count(),
        })

    return JsonResponse({'events': data})


@csrf_exempt
@token_required
def api_create_event(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST requests are allowed.'}, status=405)

    if not request.user.is_company:
        return JsonResponse({'error': 'Only recruiter accounts may create events.'}, status=403)

    try:
        data = json.loads(request.body)
    except (json.JSONDecodeError, TypeError):
        return JsonResponse({'error': 'Invalid JSON body.'}, status=400)

    title = data.get('title', '').strip()
    description = data.get('description', '').strip()
    category_id = data.get('category_id')
    start_time = parse_datetime(data.get('start_time', ''))
    end_time = parse_datetime(data.get('end_time', ''))
    total_questions = int(data.get('total_questions', 10))
    time_limit_seconds = int(data.get('time_limit_seconds', 600))
    threshold_type = data.get('threshold_type', 'TIME')
    threshold_value = int(data.get('threshold_value', 0))
    is_active = data.get('is_active', True)

    if not title or not start_time or not end_time:
        return JsonResponse({'error': 'Title, start_time, and end_time are required.'}, status=400)

    category = None
    if category_id:
        category = Category.objects.filter(id=category_id).first()

    if end_time <= start_time:
        return JsonResponse({'error': 'End time must be after start time.'}, status=400)

    event = Event.objects.create(
        recruiter=request.user,
        title=title,
        description=description,
        category=category,
        start_time=start_time,
        end_time=end_time,
        total_questions=total_questions,
        time_limit_seconds=time_limit_seconds,
        threshold_type=threshold_type,
        threshold_value=threshold_value,
        is_active=is_active,
    )

    return JsonResponse({
        'success': True,
        'event': {
            'id': event.id,
            'title': event.title,
            'description': event.description,
            'category': {
                'id': event.category.id if event.category else None,
                'name': event.category.name if event.category else None,
            } if event.category else None,
            'start_time': event.start_time.isoformat(),
            'end_time': event.end_time.isoformat(),
            'total_questions': event.total_questions,
            'time_limit_seconds': event.time_limit_seconds,
            'threshold_type': event.threshold_type,
            'threshold_value': event.threshold_value,
            'is_active': event.is_active,
            'created_at': event.created_at.isoformat(),
        }
    }, status=201)
