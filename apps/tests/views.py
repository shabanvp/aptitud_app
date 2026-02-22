from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required
from .models import Category, Question, TestAttempt, Option
import random

@login_required
def arena_home(request):
    return render(request, 'tests/arena_home.html')

@login_required
def practice_dashboard(request):
    import os
    from django.utils.text import slugify
    from django.conf import settings

    # Dynamically find company slugs from the question_bank folder
    company_base_path = os.path.join(settings.BASE_DIR, 'question_bank', 'company_level_question')
    company_slugs = []
    
    if os.path.exists(company_base_path):
        # Get all subdirectories as potential company slugs
        company_slugs = [slugify(d) for d in os.listdir(company_base_path) 
                        if os.path.isdir(os.path.join(company_base_path, d))]
    
    # Fallback to hardcoded list if folder is missing or empty (for safety)
    if not company_slugs:
        company_slugs = ['accenture', 'cognizant', 'tata-elxsi', 'tcs', 'tcs-ninja', 'wipro-elite-nlth']

    company_categories = Category.objects.filter(slug__in=company_slugs)
    general_categories = Category.objects.exclude(slug__in=company_slugs)
    
    # Priority sorting based on user's interests
    user_interests = request.user.interested_field.lower() if request.user.is_authenticated and hasattr(request.user, 'interested_field') and request.user.interested_field else ""
    
    priority_slugs = []
    
    # Tech / IT / Software / Data / Engineering
    if any(kw in user_interests for kw in ['software', 'it', 'tech', 'data', 'developer', 'computer', 'engineer']):
        priority_slugs.extend(['computer-fundamentals', 'programming-aptitude', 'debugging-and-code-logic', 'cognitive-ability'])
        
    # Management / Banking / Study Abroad
    if any(kw in user_interests for kw in ['management', 'mba', 'banking', 'business', 'finance', 'marketing', 'abroad']):
        priority_slugs.extend(['quantitative-aptitude', 'logical-reasoning', 'verbal-ability', 'memory-and-attention', 'cognitive-ability'])
        
    # Civil Services / Defense / Railways / General
    if any(kw in user_interests for kw in ['civil', 'defense', 'railway', 'general', 'government']):
        priority_slugs.extend(['general-aptitude', 'logical-reasoning', 'quantitative-aptitude', 'verbal-ability', 'memory-and-attention'])

    # Remove duplicates preserving order
    unique_priority_slugs = []
    for slug in priority_slugs:
        if slug not in unique_priority_slugs:
            unique_priority_slugs.append(slug)
            
    # List conversion for custom sorting
    sorted_general = list(general_categories)
    
    def sort_key(category):
        try:
            return unique_priority_slugs.index(category.slug)
        except ValueError:
            return len(unique_priority_slugs) # Put it at the bottom if not prioritized
            
    sorted_general.sort(key=sort_key)
    
    return render(request, 'tests/dashboard.html', {
        'categories': sorted_general,
        'company_categories': company_categories,
    })

@login_required
def start_test(request, category_slug):
    user = request.user
    if user.lives < 1:
        return render(request, 'tests/no_lives.html')

    category = get_object_or_404(Category, slug=category_slug)
    # Get questions (target 10)
    all_questions = list(Question.objects.filter(category=category))
    
    if not all_questions:
        # Handle case with 0 questions gracefully (perhaps redirect or show empty)
        # For now, let's just return empty list to template, template handles it
        questions = []
    elif len(all_questions) >= 10:
        questions = random.sample(all_questions, 10)
    else:
        # Not enough questions, fill with duplicates
        questions = all_questions[:] # Start with all unique ones
        while len(questions) < 10:
            questions.append(random.choice(all_questions))
            
        # Shuffle to mix duplicates
        random.shuffle(questions)
    
    # Store questions in session - store separate entry for distinct indices if needed
    # But since we just need IDs for checking, and we allow duplicates, logic needs to be robust.
    # The submit view iterates over session['test_questions']. 
    # If we have [1, 2, 1], the submit view will check q_1, q_2, q_1. 
    # The form needs to handle this.
    # Actually, form input names usually use question ID. duplicate IDs in form will be tricky.
    # Better approach: Generate unique 'instance IDs' or just use list index in form.
    # Let's see submit_test. It gets `question_{q_id}`.
    # If we have duplicate Question 1, both inputs will be named `question_1`.
    # HTML form will send `question_1` twice? Or last one wins?
    # FIX: We should probably not allow exact duplicates if possible, or handle them.
    # User said "allow questions to repeat". 
    # To handle repeats in a form properly, we should use a custom index for the field name.
    # e.g. `question_{index}_{q_id}`.
    
    # Let's adjust the session storage to store full structure or just rely on list order.
    # For now, let's just save list of IDs.
    
    request.session['test_questions'] = [q.id for q in questions]
    request.session['test_category'] = category.slug
    
    # Pass 1-based index to template for identifying specific instance of a question
    # (Though template loop counter does this)
    
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
        
        for index, q_id in enumerate(question_ids, start=1):
            try:
                question = Question.objects.get(id=q_id)
            except Question.DoesNotExist:
                continue
            
            if question.is_coding_problem:
                # Coding problem: get typed answer from textarea
                user_code = request.POST.get(f'code_answer_{index}', '').strip()
                
                results_details.append({
                    'question': question,
                    'is_coding': True,
                    'user_code': user_code,
                    'selected_option': None,
                    'correct_option': None,
                    'is_correct': bool(user_code),  # Mark as "attempted" if they typed something
                    'explanation': question.explanation,
                })
                if user_code:
                    score += 1  # Give credit for attempting coding problems
            else:
                # MCQ: get selected radio option
                selected_option_id = request.POST.get(f'answer_{index}')
                
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
                    'is_coding': False,
                    'user_code': '',
                    'selected_option': selected_option,
                    'correct_option': correct_option,
                    'is_correct': is_correct,
                    'explanation': question.explanation,
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
        test_category_slug = request.session.get('test_category')
        test_category = None
        if test_category_slug:
             test_category = Category.objects.filter(slug=test_category_slug).first()

        TestAttempt.objects.create(
            user=user,
            category=test_category,
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
