import os
import django
import sys

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from tests.models import Category, Question

print("Existing Categories and Question Counts:")
for cat in Category.objects.all():
    count = Question.objects.filter(category=cat).count()
    print(f"- {cat.name} (Slug: {cat.slug}): {count} questions")
