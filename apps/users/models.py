from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    level = models.PositiveIntegerField(default=1)
    exp = models.PositiveIntegerField(default=0)
    coins = models.PositiveIntegerField(default=0)
    lives = models.PositiveIntegerField(default=5)
    last_life_refill = models.DateTimeField(null=True, blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    
    # Onboarding Fields
    current_status = models.CharField(max_length=50, blank=True)
    interested_field = models.CharField(max_length=255, blank=True)

    def __str__(self):
        return self.username
