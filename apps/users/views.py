from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import login
from django.contrib.auth.decorators import login_required
from django.db.models import Avg, Count, F, Q
from django.core.serializers.json import DjangoJSONEncoder
from django.http import JsonResponse
from django.utils import timezone
import json

from users.forms import CustomUserCreationForm, CertificateForm, UserUpdateForm
from users.forms import CustomUserCreationForm, CertificateForm, UserUpdateForm
from users.models import CustomUser, Conversation, Message, Certificate
from tests.models import TestAttempt
import django.contrib.auth

def onboarding_status(request):
    if request.method == 'POST':
        status = request.POST.get('status')
        if status:
            request.session['onboarding_status'] = status
            return redirect('onboarding_interest')
    return render(request, 'users/onboarding_status.html')

def onboarding_interest(request):
    if request.method == 'POST':
        interest = request.POST.get('interest')
        if interest:
            request.session['onboarding_interest'] = interest
            return redirect('register')
    return render(request, 'users/onboarding_interest.html')

def role_selection(request):
    if request.method == 'POST':
        role = request.POST.get('role')
        if role == 'company':
            request.session['is_company'] = True
            return redirect('company_onboarding')
        else:
            request.session['is_company'] = False
            return redirect('onboarding_status')
    return render(request, 'users/role_selection.html')

def company_onboarding(request):
    if request.method == 'POST':
        hiring_focus = request.POST.get('hiring_focus')
        if hiring_focus:
            request.session['hiring_focus'] = hiring_focus
            return redirect('register')
    return render(request, 'users/company_onboarding.html')

def register(request):
    if request.method == 'POST':
        form = CustomUserCreationForm(request.POST)
        if form.is_valid():
            user = form.save(commit=False)
            
            # Check for company role
            is_company = request.session.get('is_company', False)
            user.is_company = is_company
            
            if is_company:
                user.hiring_focus = request.session.get('hiring_focus', '')
                # Clear session
                request.session.pop('is_company', None)
                request.session.pop('hiring_focus', None)
            else:
                # Apply candidate onboarding data
                user.current_status = request.session.get('onboarding_status', '')
                user.interested_field = request.session.get('onboarding_interest', '')
                # Clear session
                request.session.pop('onboarding_status', None)
                request.session.pop('onboarding_interest', None)
            
            user.save()
            
            login(request, user)
            if is_company:
                return redirect('company_dashboard')
            return redirect('home')
    else:
        form = CustomUserCreationForm()
    return render(request, 'users/register.html', {'form': form})


@login_required
def company_dashboard(request):
    if not request.user.is_company:
        return redirect('practice_dashboard')
        
    # Recruiters want to see top talent
    # Order by Level (desc), then EXP (desc)
    # We can also filter by their hiring focus if we implement matching logic later
    candidates = CustomUser.objects.filter(is_company=False).order_by('-level', '-exp')[:50]
    
    return render(request, 'users/company_dashboard.html', {'candidates': candidates})

@login_required
def profile(request, username=None):
    if username:
        user = get_object_or_404(CustomUser, username=username)
    else:
        user = request.user
        
    attempts = TestAttempt.objects.filter(user=user).order_by('completed_at')
    
    # 1. Progress History (Line Chart)
    # Get last 20 attempts for cleaner graph
    recent_attempts = attempts.reverse()[:20][::-1]
    
    dates = [a.completed_at.strftime('%d %b') for a in recent_attempts]
    scores = [a.score for a in recent_attempts]
    
    # 2. Subject Performance (Radar/Bar)
    # Aggregate avg score per category
    cat_stats = TestAttempt.objects.filter(user=user).values('category__name').annotate(
        avg_score=Avg('score'),
        count=Count('id')
    ).exclude(category__isnull=True)
    
    cat_labels = [c['category__name'] for c in cat_stats]
    cat_scores = [round(c['avg_score'], 1) for c in cat_stats]

    context = {
        'chart_dates': json.dumps(dates, cls=DjangoJSONEncoder),
        'chart_scores': json.dumps(scores, cls=DjangoJSONEncoder),
        'cat_labels': json.dumps(cat_labels, cls=DjangoJSONEncoder),
        'cat_scores': json.dumps(cat_scores, cls=DjangoJSONEncoder),
    }
    
    # If viewing someone else's profile (e.g., Recruiter viewing Candidate)
    if username and username != request.user.username:
        context['candidate'] = user
        return render(request, 'users/candidate_profile.html', context)
        
    # Get user's certificates
    context['certificates'] = user.certificates.all().order_by('-uploaded_at')
    context['certificate_form'] = CertificateForm()

    return render(request, 'users/profile.html', context)

@login_required
def edit_profile(request):
    if request.method == 'POST':
        form = UserUpdateForm(request.POST, instance=request.user)
        if form.is_valid():
            form.save()
            return redirect('profile')
    else:
        form = UserUpdateForm(instance=request.user)
    
    return render(request, 'users/edit_profile.html', {'form': form})

@login_required
def upload_certificate(request):
    if request.method == 'POST':
        form = CertificateForm(request.POST, request.FILES)
        if form.is_valid():
            certificate = form.save(commit=False)
            certificate.user = request.user
            certificate.save()
    return redirect('profile')

@login_required
def delete_certificate(request, certificate_id):
    if request.method == 'POST':
        certificate = get_object_or_404(Certificate, id=certificate_id)
        if certificate.user == request.user:
            certificate.delete()
    return redirect('profile')

@login_required
def inbox(request):
    conversations = Conversation.objects.filter(participants=request.user).order_by('-updated_at')
    # augment conversations with the 'other' user
    for conv in conversations:
        conv.other_user = conv.participants.exclude(id=request.user.id).first()
        conv.last_message = conv.messages.last()
        
    return render(request, 'users/inbox.html', {'conversations': conversations})

@login_required
def start_chat(request, username):
    target_user = get_object_or_404(CustomUser, username=username)
    if target_user == request.user:
        return redirect('inbox')
        
    # Check if conversation exists
    # Filtering for conversation that has both participants
    # This is slightly tricky with ManyToMany, simpler to check intersection
    # But simpler query:
    conversations = Conversation.objects.filter(participants=request.user).filter(participants=target_user)
    
    if conversations.exists():
        conversation = conversations.first()
    else:
        conversation = Conversation.objects.create()
        conversation.participants.add(request.user, target_user)
        
    return redirect('chat_detail', conversation_id=conversation.id)

@login_required
def chat_detail(request, conversation_id):
    conversation = get_object_or_404(Conversation, participants=request.user, id=conversation_id)
    other_user = conversation.participants.exclude(id=request.user.id).first()
    
    # Mark unread messages as read (simple implementation)
    conversation.messages.filter(is_read=False).exclude(sender=request.user).update(is_read=True)
    
    messages = conversation.messages.all().order_by('timestamp')
    
    return render(request, 'users/chat.html', {
        'conversation': conversation,
        'other_user': other_user,
        'messages': messages
    })

@login_required
def send_message(request, conversation_id):
    if request.method == 'POST':
        conversation = get_object_or_404(Conversation, participants=request.user, id=conversation_id)
        content = request.POST.get('content')
        
        if content:
            msg = Message.objects.create(
                conversation=conversation,
                sender=request.user,
                content=content
            )
            conversation.updated_at = timezone.now()
            conversation.save()
            
            # If AJAX request, return JSON
            if request.headers.get('x-requested-with') == 'XMLHttpRequest':
                return JsonResponse({
                    'status': 'success',
                    'content': msg.content,
                    'timestamp': msg.timestamp.strftime('%H:%M'),
                    'sender': msg.sender.username
                })
                
    return redirect('chat_detail', conversation_id=conversation_id)

def home(request):
    return render(request, 'landing.html')

def admin_access(request):
    if request.method == 'POST':
        password = request.POST.get('password')
        if password == 'AdminSecret123':
            # Log in as superuser
            User = django.contrib.auth.get_user_model()
            # Try to get a superuser or create one
            superuser = User.objects.filter(is_superuser=True).first()
            if not superuser:
                superuser = User.objects.create_superuser('admin', 'admin@example.com', 'admin')
            
            login(request, superuser)
            login(request, superuser)
            return redirect('custom_admin_dashboard')
        else:
            return render(request, 'users/admin_login.html', {'error': 'Invalid Password'})
            
    return render(request, 'users/admin_login.html')

@login_required
def custom_admin_dashboard(request):
    if not request.user.is_superuser:
        return redirect('home')

    # 1. Question Bank Handling
    from tests.models import Category, Question
    categories = Category.objects.annotate(q_count=Count('questions')).order_by('-q_count')
    total_questions = Question.objects.count()
    
    # 2. Monthly Active Users Graph (Mocking activity with date_joined for now)
    # Group by month
    from django.db.models.functions import TruncMonth
    user_growth = CustomUser.objects.annotate(month=TruncMonth('date_joined')).values('month').annotate(count=Count('id')).order_by('month')
    
    growth_labels = [entry['month'].strftime('%b %Y') for entry in user_growth]
    growth_data = [entry['count'] for entry in user_growth]
    
    # 3. Multiplayer Arenas (Mock Data)
    multiplayer_stats = {
        'active_rooms': 14,
        'queue_time_ms': 350,
        'latency_ms': 24,
        'total_matches_today': 128
    }
    
    # 4. User Reports (Mock Data)
    user_reports = [
        {'id': 101, 'username': 'shadow_runner', 'reason': 'Botting', 'date': '2026-02-08', 'status': 'Pending'},
        {'id': 102, 'username': 'glitch_master', 'reason': 'Exploiting Bug', 'date': '2026-02-09', 'status': 'Reviewing'},
        {'id': 103, 'username': 'toxic_player_99', 'reason': 'Harassment', 'date': '2026-02-09', 'status': 'Pending'},
    ]
    
    context = {
        'categories': categories,
        'total_questions': total_questions,
        'growth_labels': json.dumps(growth_labels),
        'growth_data': json.dumps(growth_data),
        'multiplayer_stats': multiplayer_stats,
        'user_reports': user_reports,
        'total_users': CustomUser.objects.count()
    }
    
    return render(request, 'custom_admin/dashboard.html', context)
