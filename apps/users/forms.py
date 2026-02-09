from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth import get_user_model
from users.models import Certificate

User = get_user_model()

class CustomUserCreationForm(UserCreationForm):
    class Meta:
        model = User
        fields = ('username', 'email')

class CertificateForm(forms.ModelForm):
    class Meta:
        model = Certificate
        fields = ['title', 'file']
