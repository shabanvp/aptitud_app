import os
import django
from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from apps.events.models import Event

print(f"{'ID':<5} {'Title':<30} {'Time Limit (s)':<15} {'Duration (min)'}")
print("-" * 65)

for event in Event.objects.all():
    print(f"{event.id:<5} {event.title[:28]:<30} {event.time_limit_seconds:<15} {event.duration_minutes}")
