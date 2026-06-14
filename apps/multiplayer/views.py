from django.conf import settings
from django.contrib.auth import login as auth_login
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.http import JsonResponse
from apps.multiplayer.models import Match, MatchPlayer
import json
import random
from apps.tests.models import Category, Question
from users.token_auth import get_user_from_token


def _login_from_token_query(request):
    """Let the Flutter app open the existing Django VS page after token login."""
    if request.user.is_authenticated:
        return True

    user = get_user_from_token(request.GET.get('token'))
    if not user:
        return False

    auth_login(request, user, backend='django.contrib.auth.backends.ModelBackend')
    return True


def _multiplayer_topics_for_user(user):
    from django.utils.text import slugify
    import os
    from django.conf import settings

    company_base_path = os.path.join(settings.BASE_DIR, 'question_bank', 'company_level_question')
    company_slugs = []

    if os.path.exists(company_base_path):
        company_slugs = [
            slugify(d) for d in os.listdir(company_base_path)
            if os.path.isdir(os.path.join(company_base_path, d))
        ]

    if not company_slugs:
        company_slugs = ['accenture', 'cognizant', 'tata-elxsi', 'tcs', 'tcs-ninja', 'wipro-elite-nlth']

    general_categories = Category.objects.exclude(slug__in=company_slugs)

    user_interests = user.interested_field.lower() if hasattr(user, 'interested_field') and user.interested_field else ""

    priority_slugs = []
    if any(kw in user_interests for kw in ['software', 'it', 'tech', 'data', 'developer', 'computer', 'engineer']):
        priority_slugs.extend(['computer-fundamentals', 'programming-aptitude', 'debugging-and-code-logic', 'cognitive-ability'])
    if any(kw in user_interests for kw in ['management', 'mba', 'banking', 'business', 'finance', 'marketing', 'abroad']):
        priority_slugs.extend(['quantitative-aptitude', 'logical-reasoning', 'verbal-ability', 'memory-and-attention', 'cognitive-ability'])
    if any(kw in user_interests for kw in ['civil', 'defense', 'railway', 'general', 'government']):
        priority_slugs.extend(['general-aptitude', 'logical-reasoning', 'quantitative-aptitude', 'verbal-ability', 'memory-and-attention'])

    unique_priority_slugs = []
    for slug in priority_slugs:
        if slug not in unique_priority_slugs:
            unique_priority_slugs.append(slug)

    sorted_general = list(general_categories)

    def sort_key(category):
        try:
            return unique_priority_slugs.index(category.slug)
        except ValueError:
            return len(unique_priority_slugs)

    sorted_general.sort(key=sort_key)
    return sorted_general

@login_required
def topic_select(request):
    """View to select a topic for multiplayer."""
    user = request.user
    context = {
        'categories': _multiplayer_topics_for_user(user),
        'coins': user.coins,
        'lives': user.lives,
    }
    return render(request, 'multiplayer/topic_select.html', context)

@login_required
def matchmaking(request, topic):
    """View that shows the roulette animation and handles WS connection."""
    user = request.user
    
    if user.coins < 20 or user.lives < 1:
        messages.error(request, 'Insufficient coins (20) or lives (1) required to play VS Mode.')
        return redirect('multiplayer:topic_select')

    context = {
        'topic': topic,
        'coins': user.coins,
        'lives': user.lives,
    }
    return render(request, 'multiplayer/matchmaking.html', context)

def game_room(request, match_id):
    """View for the actual 1v1 test interface."""
    if not _login_from_token_query(request):
        return redirect(f"{settings.LOGIN_URL}?next={request.path}")

    match = get_object_or_404(Match, id=match_id)
    
    # Verify user is in this match
    if not MatchPlayer.objects.filter(match=match, user=request.user).exists():
        messages.error(request, "You are not a participant in this match.")
        return redirect('multiplayer:topic_select')
        
    if match.status == 'completed':
        return redirect('multiplayer:results', match_id=match.id)
        
    # Get opponent details for the UI
    opponent_entry = MatchPlayer.objects.filter(match=match).exclude(user=request.user).first()
    opponent = opponent_entry.user if opponent_entry else None
    
    # Load Questions for the Game from the match instance
    selected_questions = list(match.questions.prefetch_related('options').all())
    
    context = {
        'match': match,
        'opponent': opponent,
        'questions': selected_questions
    }
    return render(request, 'multiplayer/vs_interface.html', context)

def results(request, match_id):
    """View to display match results and coin distribution."""
    if not _login_from_token_query(request):
        return redirect(f"{settings.LOGIN_URL}?next={request.path}")

    match = get_object_or_404(Match, id=match_id)
    
    players = MatchPlayer.objects.filter(match=match).select_related('user')
    me = next((p for p in players if p.user == request.user), None)
    opponent = next((p for p in players if p.user != request.user), None)
    
    if not me:
        messages.error(request, "You are not a participant in this match.")
        return redirect('multiplayer:topic_select')
        
    context = {
        'match': match,
        'my_player': me,
        'opponent_player': opponent,
        'opponent': opponent.user if opponent else None,
        'my_score': me.score if me else 0,
        'opponent_score': opponent.score if opponent else 0,
        'is_winner': me.is_winner if me else False,
        'is_tie': match.winner is None and match.status == 'completed',
        'questions': match.questions.prefetch_related('options').all()
    }
    return render(request, 'multiplayer/results.html', context)


@login_required
def match_status(request, match_id):
    """API view to poll match status."""
    match = get_object_or_404(Match, id=match_id)
    return JsonResponse({'status': match.status})


def api_topics(request):
    """GET /api/multiplayer/topics/ - Flutter topic list matching Django VS mode."""
    auth_header = request.headers.get('Authorization', '')
    token = auth_header.replace('Token ', '').strip()
    user = get_user_from_token(token)

    if not user:
        return JsonResponse({'error': 'Invalid or expired token'}, status=401)

    categories = _multiplayer_topics_for_user(user)
    return JsonResponse({
        'coins': user.coins,
        'lives': user.lives,
        'entry_fee_coins': 20,
        'entry_fee_lives': 1,
        'winner_reward_coins': 40,
        'categories': [
            {
                'id': category.id,
                'name': category.name,
                'slug': category.slug,
                'description': category.description,
                'question_count': category.questions.count(),
            }
            for category in categories
        ],
    })
