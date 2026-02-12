import os
import django
from django.utils import timezone
from datetime import timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from events.models import Event

def fix_legacy_event():
    print("Fixing Legacy Event Duration...")
    
    try:
        # Fetch event ID 5
        event = Event.objects.get(id=5)
        print(f"Found Event: {event.title}")
        print(f"Current Start: {event.start_time}")
        print(f"Current End:   {event.end_time}")
        print(f"Duration Mins: {event.duration_minutes}")
        
        # Calculate new end time based on duration_minutes (test duration)
        # We want End Time = Start Time + Duration Minutes
        new_end_time = event.start_time + timedelta(minutes=event.duration_minutes)
        
        event.end_time = new_end_time
        event.save()
        
        print(f"Updated End:   {event.end_time}")
        print("Success: Event end time updated.")
        
    except Event.DoesNotExist:
        print("Error: Event ID 5 not found.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    fix_legacy_event()
