from django.shortcuts import render, redirect
from django.contrib.auth import login
from django.contrib.auth.decorators import login_required
from .forms import CustomUserCreationForm

def onboarding_status(request):
    if request.method == 'POST':
        status = request.POST.get('status')
        if status:
            request.session['onboarding_status'] = status
            return redirect('onboarding_interest')
    return render(request, 'users/onboarding_status.html')

def onboarding_interest(request):
    if request.method == 'POST':
        interest = request.POST.get('interest')
        if interest:
            request.session['onboarding_interest'] = interest
            return redirect('register')
    return render(request, 'users/onboarding_interest.html')

def register(request):
    if request.method == 'POST':
        form = CustomUserCreationForm(request.POST)
        if form.is_valid():
            user = form.save(commit=False)
            
            # Apply onboarding data from session
            user.current_status = request.session.get('onboarding_status', '')
            user.interested_field = request.session.get('onboarding_interest', '')
            
            user.save()
            
            # Clear session data
            request.session.pop('onboarding_status', None)
            request.session.pop('onboarding_interest', None)
            
            login(request, user)
            return redirect('home')
    else:
        form = CustomUserCreationForm()
    return render(request, 'users/register.html', {'form': form})

@login_required
def profile(request):
    return render(request, 'users/profile.html')

def home(request):
    return render(request, 'landing.html')
