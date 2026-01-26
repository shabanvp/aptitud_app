from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required
from .models import Category, Question, TestAttempt, Option
import random

@login_required
def arena_home(request):
    return render(request, 'tests/arena_home.html')

@login_required
def practice_dashboard(request):
    categories = Category.objects.all()
    return render(request, 'tests/dashboard.html', {'categories': categories})

@login_required
def start_test(request, category_slug):
    user = request.user
    if user.lives < 1:
        return render(request, 'tests/no_lives.html')

    category = get_object_or_404(Category, slug=category_slug)
    # Get random questions (e.g., 5)
    questions = list(Question.objects.filter(category=category))
    if len(questions) > 5:
        questions = random.sample(questions, 5)
    
    # Store questions in session
    request.session['test_questions'] = [q.id for q in questions]
    request.session['test_category'] = category.slug
    
    return render(request, 'tests/test_interface.html', {'questions': questions, 'category': category})

@login_required
def submit_test(request):
    if request.method == 'POST':
        question_ids = request.session.get('test_questions', [])
        if not question_ids:
            return redirect('practice_dashboard')

        results_details = []
        score = 0
        total = len(question_ids)
        
        for q_id in question_ids:
            try:
                question = Question.objects.get(id=q_id)
            except Question.DoesNotExist:
                continue
                
            selected_option_id = request.POST.get(f'question_{q_id}')
            selected_option = None
            if selected_option_id:
                selected_option = Option.objects.filter(id=selected_option_id).first()
            
            correct_option = question.options.filter(is_correct=True).first()
            
            is_correct = False
            if selected_option and selected_option.is_correct:
                score += 1
                is_correct = True
            
            results_details.append({
                'question': question,
                'selected_option': selected_option,
                'correct_option': correct_option,
                'is_correct': is_correct,
                'explanation': question.explanation
            })
        
        # Calculate Rewards
        coins = score * 10
        exp = score * 20
        
        # Update User
        user = request.user
        if user.lives > 0:
            user.lives -= 1
        
        user.coins += coins
        user.exp += exp
        # specific level logic: level = 1 + exp // 100
        new_level = 1 + (user.exp // 100)
        leveled_up = new_level > user.level
        user.level = new_level
        user.save()
        
        # Save Attempt
        TestAttempt.objects.create(
            user=user,
            score=score,
            total_questions=total,
            coins_earned=coins,
            exp_earned=exp,
            mode='SOLO'
        )
        
        del request.session['test_questions']
        
        context = {
            'score': score,
            'total': total,
            'coins': coins,
            'exp': exp,
            'leveled_up': leveled_up,
            'new_level': new_level,
            'results_details': results_details
        }
        return render(request, 'tests/result.html', context)
    return redirect('practice_dashboard')
