import os
import django
import sys

# Flush stdout to ensure we catch all output
sys.stdout.reconfigure(encoding='utf-8')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from django.apps import apps
from django.conf import settings
from django.utils.text import slugify

Category = apps.get_model('tests', 'Category')
Question = apps.get_model('tests', 'Question')

company_base_path = os.path.join(settings.BASE_DIR, 'question_bank', 'company_level_question')

if not os.path.exists(company_base_path):
    print(f"Directory NOT found: {company_base_path}")
    sys.exit(1)

print(f"Scanning {company_base_path}...")

total_imported = 0

for company_dir in os.listdir(company_base_path):
    company_path = os.path.join(company_base_path, company_dir)
    if not os.path.isdir(company_path):
        continue

    slug = slugify(company_dir)
    try:
        category = Category.objects.get(slug=slug)
    except Category.DoesNotExist:
        print(f"Skipping {company_dir} (Category not found)")
        continue

    print(f"Processing {company_dir}...")
    
    for q_dir in os.listdir(company_path):
        q_path = os.path.join(company_path, q_dir)
        if not os.path.isdir(q_path):
            continue
            
        # Check for Problem Statement.txt
        txt_path = os.path.join(q_path, 'Problem Statement.txt')
        if not os.path.exists(txt_path):
            print(f"  [SKIP] No 'Problem Statement.txt' in {q_dir}")
            continue

        with open(txt_path, 'r', encoding='utf-8', errors='ignore') as f:
            text = f.read()

        # Check for Main.java (Explanation/Solution)
        java_path = os.path.join(q_path, 'Main.java')
        explanation = ""
        if os.path.exists(java_path):
            with open(java_path, 'r', encoding='utf-8', errors='ignore') as f:
                code = f.read()
                explanation = f"Reference Solution:\n\n```java\n{code}\n```"

        # Create or Update Question
        # Use first 100 chars as identifier to avoid duplicates if re-running
        topic_preview = text[:100] if len(text) > 100 else text
        
        question, created = Question.objects.get_or_create(
            category=category,
            text=text,
            defaults={
                'explanation': explanation,
                'difficulty': 'MEDIUM' # Default
            }
        )

        if created:
            print(f"  [IMPORTED] {q_dir}")
            total_imported += 1
        else:
            # print(f"  [EXISTS] {q_dir}")
            pass

print(f"\nTotal Questions Imported: {total_imported}")
print("Done.")
