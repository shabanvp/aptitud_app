from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import login, logout
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.db.models import Avg, Count, F, Q
from django.core.serializers.json import DjangoJSONEncoder
from django.http import JsonResponse
from django.utils import timezone
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
import json

from users.forms import CustomUserCreationForm, CertificateForm, UserUpdateForm
from users.forms import CustomUserCreationForm, CertificateForm, UserUpdateForm
from apps.users.models import CustomUser, Conversation, Message, Certificate
from apps.tests.models import TestAttempt
from gamification.models import MonthlySpin
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

def _send_verification_email(request, user, redirect_to=None):
    """Helper: build and send the token-based verification email."""
    uid   = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    domain = request.get_host()
    verify_url = f"http://{domain}/verify-email/{uid}/{token}/"
    if redirect_to:
        from urllib.parse import quote
        verify_url += f"?next={quote(redirect_to)}"

    context = {
        'user': user,
        'verify_url': verify_url,
    }
    subject = "Verify your Aptitude GO account"
    body_html = render_to_string('users/email/verify_email.html', context)
    body_text = (
        f"Hi {user.username},\n\n"
        f"Please verify your email by visiting:\n{verify_url}\n\n"
        "If you did not create this account, ignore this email.\n\n"
        "– Aptitude GO Team"
    )

    email = EmailMultiAlternatives(
        subject=subject,
        body=body_text,
        from_email=None,          # uses DEFAULT_FROM_EMAIL from settings
        to=[user.email],
    )
    email.attach_alternative(body_html, "text/html")
    email.send(fail_silently=False)


def register(request):
    if request.method == 'POST':
        form = CustomUserCreationForm(request.POST)
        if form.is_valid():
            user = form.save(commit=False)

            # Collect onboarding session data
            is_company = request.session.get('is_company', False)
            user.is_company = is_company

            if is_company:
                user.hiring_focus = request.session.get('hiring_focus', '')
                request.session.pop('is_company', None)
                request.session.pop('hiring_focus', None)
            else:
                user.current_status    = request.session.get('onboarding_status', '')
                user.interested_field  = request.session.get('onboarding_interest', '')
                request.session.pop('onboarding_status', None)
                request.session.pop('onboarding_interest', None)

            # Activate immediately (no email verification required)
            user.is_active = True
            user.save()

            return redirect('login')
    else:
        form = CustomUserCreationForm()
    return render(request, 'users/register.html', {'form': form})


def email_sent(request):
    """Tell the user to check their inbox."""
    return render(request, 'users/email_sent.html')


def verify_email(request, uidb64, token):
    """Activate the account when the user clicks the email link."""
    try:
        uid  = force_str(urlsafe_base64_decode(uidb64))
        user = CustomUser.objects.get(pk=uid)
    except (TypeError, ValueError, OverflowError, CustomUser.DoesNotExist):
        user = None

    next_url = request.GET.get('next', '')

    if user is not None and default_token_generator.check_token(user, token):
        user.is_active = True
        user.save()
        return render(request, 'users/email_verify_success.html', {'success': True, 'next': next_url})
    else:
        return render(request, 'users/email_verify_success.html', {'success': False, 'next': next_url})


@login_required
def company_dashboard(request):
    if not request.user.is_company:
        return redirect('practice_dashboard')
        
    # Recruiters want to see top talent
    candidates = CustomUser.objects.filter(is_company=False).order_by('-level', '-exp')[:50]
    
    # Calculate new candidates in the last 7 days
    seven_days_ago = timezone.now() - timezone.timedelta(days=7)
    new_candidates_count = CustomUser.objects.filter(is_company=False, date_joined__gte=seven_days_ago).count()
    
    return render(request, 'users/company_dashboard.html', {
        'candidates': candidates,
        'new_candidates_count': new_candidates_count
    })

@login_required
def profile(request, username=None):
    if username:
        user = get_object_or_404(CustomUser, username=username)
    else:
        user = request.user
    
    context = {}
    
    # If viewing someone else's profile (e.g., Recruiter viewing Candidate)
    if username and username != request.user.username:
        # Standard candidate view logic
        attempts = TestAttempt.objects.filter(user=user).order_by('completed_at')
        recent_attempts = attempts.reverse()[:20][::-1]
        dates = [a.completed_at.strftime('%d %b') for a in recent_attempts]
        scores = [a.score for a in recent_attempts]
        
        cat_stats = TestAttempt.objects.filter(user=user).values('category__name').annotate(
            avg_score=Avg('score'), count=Count('id')
        ).exclude(category__isnull=True)
        cat_labels = [c['category__name'] for c in cat_stats]
        cat_scores = [round(c['avg_score'], 1) for c in cat_stats]

        context.update({
            'chart_dates': json.dumps(dates, cls=DjangoJSONEncoder),
            'chart_scores': json.dumps(scores, cls=DjangoJSONEncoder),
            'cat_labels': json.dumps(cat_labels, cls=DjangoJSONEncoder),
            'cat_scores': json.dumps(cat_scores, cls=DjangoJSONEncoder),
            'candidate': user
        })
        return render(request, 'users/candidate_profile.html', context)
    
    # Viewing Own Profile
    if user.is_superuser:
        # ADMIN PROFILE LOGIC
        from django.contrib.admin.models import LogEntry
        # Fetch recent admin actions
        admin_logs = LogEntry.objects.filter(user=user).select_related('content_type').order_by('-action_time')[:10]
        context['admin_logs'] = admin_logs
        
    elif user.is_company:
        # COMPANY PROFILE LOGIC
        # 1. Conversations Count
        conv_count = Conversation.objects.filter(participants=user).count()
        # 2. Candidates Contacted (Distinct users in conversations excluding self)
        # simplistic approach for now: just using conversation count as proxy or fetching
        
        context['conv_count'] = conv_count
        # We can add more stats later
    else:
        # CANDIDATE PROFILE LOGIC
        attempts = TestAttempt.objects.filter(user=user).order_by('completed_at')
        recent_attempts = attempts.reverse()[:20][::-1]
        dates = [a.completed_at.strftime('%d %b') for a in recent_attempts]
        scores = [a.score for a in recent_attempts]
        
        cat_stats = TestAttempt.objects.filter(user=user).values('category__name').annotate(
            avg_score=Avg('score'), count=Count('id')
        ).exclude(category__isnull=True)
        cat_labels = [c['category__name'] for c in cat_stats]
        cat_scores = [round(c['avg_score'], 1) for c in cat_stats]

        context.update({
            'chart_dates': json.dumps(dates, cls=DjangoJSONEncoder),
            'chart_scores': json.dumps(scores, cls=DjangoJSONEncoder),
            'cat_labels': json.dumps(cat_labels, cls=DjangoJSONEncoder),
            'cat_scores': json.dumps(cat_scores, cls=DjangoJSONEncoder),
            'certificates': user.certificates.all().order_by('-uploaded_at'),
            'certificate_form': CertificateForm()
        })

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
def delete_account(request):
    """
    Permanently deletes the user's account and all associated data,
    freeing up the email address for reuse.
    """
    if request.method == 'POST':
        user = request.user
        logout(request)
        user.delete()
        messages.success(request, "Your account has been permanently deleted.")
        return redirect('home')
    return redirect('profile')

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
    show_wheel_modal = False
    if request.user.is_authenticated:
        if request.user.is_superuser:
            return redirect('custom_admin_dashboard')
        if request.user.is_company:
            return redirect('company_dashboard')
            
        # Check reward wheel eligibility for Candidates
        user = request.user
        now = timezone.now()
        has_spun_this_month = MonthlySpin.objects.filter(
            user=user,
            spin_date__year=now.year,
            spin_date__month=now.month
        ).exists()
        show_wheel_modal = not has_spun_this_month
            
    return render(request, 'landing.html', {'show_wheel_modal': show_wheel_modal})

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
            
            # Specify the backend since we have auth multiple backends configured
            superuser.backend = 'django.contrib.auth.backends.ModelBackend'
            login(request, superuser)
            return redirect('custom_admin_dashboard')
        else:
            return render(request, 'users/admin_login.html', {'error': 'Invalid Password'})
            
    return render(request, 'users/admin_login.html')

@login_required
def custom_admin_dashboard(request):
    if not request.user.is_superuser:
        return redirect('home')
        
    from apps.users.models import SiteSetting
    settings = SiteSetting.get_settings()
    
    if request.method == 'POST' and 'toggle_malpractice' in request.POST:
        settings.anti_malpractice_enabled = not settings.anti_malpractice_enabled
        settings.save()
        return redirect('custom_admin_dashboard')

    # 1. Overview Stats
    from apps.tests.models import Category, Question, TestAttempt
    from gamification.models import StoreItem, UserItem
    
    total_users = CustomUser.objects.count()
    total_questions = Question.objects.count()
    total_tests_taken = TestAttempt.objects.count()
    total_items_sold = UserItem.objects.count()
    
    # 2. Monthly Active Users Graph
    from django.db.models.functions import TruncMonth
    user_growth = CustomUser.objects.annotate(month=TruncMonth('date_joined')).values('month').annotate(count=Count('id')).order_by('month')
    
    growth_labels = [entry['month'].strftime('%b %Y') for entry in user_growth]
    growth_data = [entry['count'] for entry in user_growth]
    
    # 3. Recent Users (Replacing Reports)
    recent_users = CustomUser.objects.order_by('-date_joined')[:5]
    
    # 4. Popular Items (Replacing Multiplayer Stats)
    popular_items = StoreItem.objects.annotate(sold_count=Count('useritem')).order_by('-sold_count')[:5]
    
    # 5. Question Bank Stats
    categories = Category.objects.annotate(q_count=Count('questions')).order_by('-q_count')

    context = {
        'total_users': total_users,
        'total_questions': total_questions,
        'total_tests_taken': total_tests_taken,
        'total_items_sold': total_items_sold,
        'growth_labels': json.dumps(growth_labels),
        'growth_data': json.dumps(growth_data),
        'recent_users': recent_users,
        'popular_items': popular_items,
        'categories': categories,
        'anti_malpractice_enabled': settings.anti_malpractice_enabled,
    }
    
    return render(request, 'custom_admin/dashboard.html', context)

@login_required
def admin_delete_user(request, user_id):
    """
    Allows a superuser to permanently delete another user's account from the dashboard.
    """
    if not request.user.is_superuser:
        return redirect('home')
        
    if request.method == 'POST':
        target_user = get_object_or_404(CustomUser, id=user_id)
        
        # Prevent superusers from accidentally deleting themselves via the dashboard
        if target_user.id == request.user.id:
            messages.error(request, "You cannot delete your own admin account from here.")
        else:
            username = target_user.username
            target_user.delete()
            messages.success(request, f"User '{username}' was permanently deleted.")
            
    return redirect('custom_admin_dashboard')

import json
from django.http import JsonResponse
from apps.users.models import AIChatMessage
from django.views.decorators.csrf import csrf_protect

@login_required
@csrf_protect
def aptix_chat_api(request):
    """
    Receives chat messages from the Aptix popup, compiles context, and queries the LLM.
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)
        
    try:
        data = json.loads(request.body)
        user_msg = data.get('message', '').strip()
        if not user_msg:
            return JsonResponse({'error': 'No message provided'}, status=400)
            
        # 1. Save user message to memory
        new_user_msg = AIChatMessage.objects.create(user=request.user, role='user', content=user_msg)
        
        # 2. Build the System Context Prompt
        wallet = getattr(request.user, 'coins', 0)
        health = getattr(request.user, 'lives', 5)

        system_context = f"""
        [ROLE]
        You are 'Aptix', a friendly, concise AI Mentor for the 'Aptitude GO' platform.
        Rule 1: Never give direct answers to live test questions.
        Rule 2: Motivate the user and explain concepts clearly.
        Rule 3: Keep your answers very short and conversational. Use emojis.
        
        [USER REALTIME STATS]
        Name: {request.user.first_name or request.user.username}
        Level: {request.user.level} (XP: {request.user.exp})
        Wallet: {wallet} Coins
        Health: {health}/5 Lives
        Dream Job: {request.user.interested_field}
        """
        
        # 3. Initialize Gemini
        import google.generativeai as genai
        from django.conf import settings
        
        api_key = getattr(settings, 'GEMINI_API_KEY', None)
        if not api_key:
             return JsonResponse({'success': True, 'response': "API Key not found in backend."})

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel(
            model_name="gemini-2.5-flash",
            system_instruction=system_context
        )
        
        # Build history format for Gemini
        previous_msgs = AIChatMessage.objects.filter(user=request.user).exclude(id=new_user_msg.id).order_by('-timestamp')[:10]
        history = []
        # Reverse to chronological order
        for msg in reversed(previous_msgs):
            history_role = 'user' if msg.role == 'user' else 'model'
            history.append(
                {"role": history_role, "parts": [msg.content]}
            )
            
        chat_session = model.start_chat(history=history)
        response = chat_session.send_message(user_msg)
        bot_response = response.text
        
        # 4. Save Bot response to memory
        AIChatMessage.objects.create(user=request.user, role='assistant', content=bot_response)
        
        return JsonResponse({'success': True, 'response': bot_response})
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import authenticate, get_user_model
from django.core.signing import TimestampSigner, BadSignature, SignatureExpired
from functools import wraps

def token_required(view_func):
    """
    Decorator for API views that require token-based authentication.
    Passes the authenticated user in request.user.
    """
    @wraps(view_func)
    def wrapped_view(request, *args, **kwargs):
        User = get_user_model()
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Token '):
            return JsonResponse({'error': 'Authentication credentials were not provided.'}, status=401)
        
        token = auth_header.split(' ')[1]
        signer = TimestampSigner()
        try:
            # Token is valid for 30 days
            username = signer.unsign(token, max_age=30 * 24 * 3600)
            request.user = User.objects.get(username=username)
        except (SignatureExpired, BadSignature, User.DoesNotExist):
            return JsonResponse({'error': 'Invalid or expired token.'}, status=401)
        
        return view_func(request, *args, **kwargs)
    return wrapped_view


def _api_user_payload(user, include_profile_stats=False):
    payload = {
        'id': str(user.id),
        'username': user.username,
        'email': user.email,
        'level': user.level,
        'exp': user.exp,
        'coins': user.coins,
        'lives': user.lives,
        'avatar': user.avatar.url if getattr(user, 'avatar', None) else '',
        'is_company': user.is_company,
        'current_status': user.current_status,
        'interested_field': user.interested_field,
        'hiring_focus': user.hiring_focus,
        'organization': user.organization,
        'date_joined': user.date_joined.isoformat() if user.date_joined else None,
    }

    if include_profile_stats and not user.is_company:
        attempts = TestAttempt.objects.filter(user=user).order_by('-completed_at')
        payload['total_attempts'] = attempts.count()
        payload['recent_attempts'] = [
            {
                'category': attempt.category.name if attempt.category else 'General',
                'score': attempt.score,
                'completed_at': attempt.completed_at.isoformat() if attempt.completed_at else None,
            }
            for attempt in attempts[:5]
        ]
        payload['category_stats'] = [
            {
                'category': stat['category__name'] or 'General',
                'avg_score': round(stat['avg_score'], 1) if stat['avg_score'] is not None else 0.0,
                'count': stat['count'],
            }
            for stat in TestAttempt.objects.filter(user=user)
            .values('category__name')
            .annotate(avg_score=Avg('score'), count=Count('id'))
            .exclude(category__isnull=True)
        ]

    return payload


@csrf_exempt
def api_login(request):
    """
    API endpoint for logging in.
    Accepts: username (or email) and password in JSON body.
    Returns: Signed auth token and user details.
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST requests are allowed.'}, status=405)
    
    try:
        data = json.loads(request.body)
        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
    except (json.JSONDecodeError, TypeError):
        return JsonResponse({'error': 'Invalid JSON body.'}, status=400)
        
    if not username or not password:
        return JsonResponse({'error': 'Username/email and password are required.'}, status=400)
        
    # Check if user exists first to see if they are inactive
    User = get_user_model()
    try:
        user_check = User.objects.filter(
            Q(username__iexact=username) | Q(email__iexact=username)
        ).first()
    except Exception:
        user_check = None
        
    if user_check and not user_check.is_active:
        return JsonResponse({'error': 'Your account is inactive. Please verify your email first.'}, status=403)
        
    if user_check is None or not user_check.check_password(password):
        return JsonResponse({'error': 'Invalid credentials.'}, status=401)
    if not user_check.is_active:
        return JsonResponse({'error': 'Your account is inactive. Please verify your email first.'}, status=403)

    user = user_check
        
    # Generate a signed token using TimestampSigner
    signer = TimestampSigner()
    token = signer.sign(user.username)
    
    return JsonResponse({
        'token': token,
        'user': _api_user_payload(user),
    })


@csrf_exempt
@token_required
def api_profile(request, username=None):
    if request.method != 'GET':
        return JsonResponse({'error': 'Only GET requests are allowed.'}, status=405)

    if username:
        user = get_object_or_404(CustomUser, username=username)
    else:
        user = request.user

    return JsonResponse({'profile': _api_user_payload(user, include_profile_stats=True)}, status=200)


@csrf_exempt
@token_required
def api_profile_update(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST requests are allowed.'}, status=405)

    try:
        data = json.loads(request.body)
    except (json.JSONDecodeError, TypeError):
        return JsonResponse({'error': 'Invalid JSON body.'}, status=400)

    user = request.user
    for field in ('first_name', 'last_name', 'current_status', 'interested_field', 'organization', 'hiring_focus'):
        if field in data:
            setattr(user, field, data.get(field) or '')
    user.save()

    return JsonResponse({'profile': _api_user_payload(user, include_profile_stats=True)}, status=200)


@csrf_exempt
def api_register(request):
    """
    API endpoint for registering a new user.
    Accepts: username, email, password, is_company, and role-specific fields.
    Sets is_active=False and sends verification email.
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST requests are allowed.'}, status=405)
        
    try:
        data = json.loads(request.body)
    except (json.JSONDecodeError, TypeError):
        return JsonResponse({'error': 'Invalid JSON body.'}, status=400)
        
    username = data.get('username', '').strip()
    email = data.get('email', '').strip()
    password = data.get('password', '').strip()
    is_company = data.get('is_company', False)
    
    # Optional onboarding fields
    current_status = data.get('current_status', '').strip()
    interested_field = data.get('interested_field', '').strip()
    hiring_focus = data.get('hiring_focus', '').strip()
    organization = data.get('organization', '').strip()
    
    if not username or not email or not password:
        return JsonResponse({'error': 'Username, email, and password are required.'}, status=400)
        
    User = get_user_model()
    existing_by_username = User.objects.filter(username__iexact=username).first()
    existing_by_email = User.objects.filter(email__iexact=email).first()

    # If the same user exists by both username and email, allow account promotion to recruiter.
    if existing_by_username or existing_by_email:
        existing_user = None
        if existing_by_username and existing_by_email:
            if existing_by_username.pk == existing_by_email.pk:
                existing_user = existing_by_username
            else:
                return JsonResponse({'error': 'Username and email are already taken by different accounts.'}, status=400)
        else:
            existing_user = existing_by_username or existing_by_email

        if existing_user:
            if existing_user.username.lower() == username.lower() and existing_user.email.lower() == email.lower():
                if is_company and not existing_user.is_company:
                    if not existing_user.check_password(password):
                        return JsonResponse({'error': 'Password does not match existing account. Please use the same password or log in instead.'}, status=400)

                    existing_user.is_company = True
                    existing_user.organization = organization
                    existing_user.hiring_focus = hiring_focus
                    if current_status:
                        existing_user.current_status = current_status
                    if interested_field:
                        existing_user.interested_field = interested_field
                    existing_user.save()

                    if not existing_user.is_active:
                        # Activate existing account immediately (skip verification email)
                        existing_user.is_active = True
                        existing_user.save()

                    return JsonResponse({
                        'success': True,
                        'message': 'Your existing account has been upgraded to recruiter. You can now log in and access recruiter features.'
                    }, status=200)

                if existing_user.is_company:
                    return JsonResponse({'error': 'A recruiter account already exists with this username/email. Please log in.'}, status=400)

                return JsonResponse({
                    'error': 'This username/email is already registered as a candidate. Use the same account to log in or select a different recruiter username/email.'
                }, status=400)

            return JsonResponse({'error': 'Username or email is already taken.'}, status=400)

    try:
        # Create user and activate immediately (no email verification)
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            is_company=is_company,
            current_status=current_status,
            interested_field=interested_field,
            hiring_focus=hiring_focus,
            organization=organization,
            is_active=True
        )
        
        # Activate immediately and return success (no email verification)
        return JsonResponse({
            'success': True,
            'message': 'Registration successful! You can now log in.'
        }, status=201)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
@token_required
def api_recruiter_candidates(request):
    if request.method != 'GET':
        return JsonResponse({'error': 'Only GET requests are allowed.'}, status=405)

    if not getattr(request.user, 'is_company', False):
        return JsonResponse({'error': 'Unauthorized access.'}, status=403)

    candidates = CustomUser.objects.filter(is_company=False).order_by('-level', '-exp')[:30]
    seven_days_ago = timezone.now() - timezone.timedelta(days=7)
    new_candidates_count = CustomUser.objects.filter(is_company=False, date_joined__gte=seven_days_ago).count()
    total_candidates = CustomUser.objects.filter(is_company=False).count()

    candidate_list = []
    for candidate in candidates:
        candidate_list.append({
            'id': str(candidate.id),
            'username': candidate.username,
            'email': candidate.email,
            'level': candidate.level,
            'exp': candidate.exp,
            'coins': candidate.coins,
            'lives': candidate.lives,
            'avatar': candidate.avatar,
            'interested_field': candidate.interested_field,
            'current_status': candidate.current_status,
            'organization': candidate.organization,
            'hiring_focus': candidate.hiring_focus,
            'date_joined': candidate.date_joined.isoformat() if candidate.date_joined else None,
        })

    return JsonResponse({
        'candidates': candidate_list,
        'new_candidates_count': new_candidates_count,
        'total_candidates': total_candidates,
    }, status=200)


@csrf_exempt
@token_required
def api_recruiter_candidate_detail(request, username):
    if request.method != 'GET':
        return JsonResponse({'error': 'Only GET requests are allowed.'}, status=405)

    if not getattr(request.user, 'is_company', False):
        return JsonResponse({'error': 'Unauthorized access.'}, status=403)

    candidate = get_object_or_404(CustomUser, username=username, is_company=False)

    attempts = TestAttempt.objects.filter(user=candidate).order_by('-completed_at')[:20]
    total_attempt_count = TestAttempt.objects.filter(user=candidate).count()
    recent_attempts = []
    for attempt in attempts:
        recent_attempts.append({
            'category': attempt.category.name if attempt.category else 'General',
            'score': attempt.score,
            'completed_at': attempt.completed_at.strftime('%d %b %Y') if attempt.completed_at else None,
        })

    cat_stats = TestAttempt.objects.filter(user=candidate).values('category__name').annotate(
        avg_score=Avg('score'),
        count=Count('id')
    ).exclude(category__isnull=True)

    category_stats = []
    for stat in cat_stats:
        category_stats.append({
            'category': stat['category__name'] or 'General',
            'avg_score': round(stat['avg_score'], 1) if stat['avg_score'] is not None else 0.0,
            'count': stat['count'],
        })

    candidate_data = {
        'id': str(candidate.id),
        'username': candidate.username,
        'email': candidate.email,
        'level': candidate.level,
        'exp': candidate.exp,
        'coins': candidate.coins,
        'lives': candidate.lives,
        'avatar': candidate.avatar,
        'interested_field': candidate.interested_field,
        'current_status': candidate.current_status,
        'organization': candidate.organization,
        'hiring_focus': candidate.hiring_focus,
        'date_joined': candidate.date_joined.isoformat() if candidate.date_joined else None,
        'total_attempts': total_attempt_count,
        'recent_attempts': recent_attempts,
        'category_stats': category_stats,
    }

    return JsonResponse({'candidate': candidate_data}, status=200)

