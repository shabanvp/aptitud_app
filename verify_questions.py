import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from tests.models import Category, Question

print(f"\n=== CATEGORIES ===")
categories = Category.objects.all()
print(f"Total categories: {categories.count()}\n")
for cat in categories:
    q_count = cat.questions.count()
    print(f"✓ {cat.name} ({cat.slug}) - {q_count} questions")

print(f"\n=== QUESTIONS ===")
print(f"Total questions: {Question.objects.count()}\n")
for q in Question.objects.all()[:5]:
    print(f"- [{q.category.name}] {q.text[:60]}...")
    print(f"  Difficulty: {q.difficulty}, Options: {q.options.count()}\n")
