from django.urls import path
from django.contrib.auth import views as auth_views
from users import views

urlpatterns = [
    path('', views.home, name='home'),
    path('get-started/', views.onboarding_status, name='onboarding_status'),
    path('get-started/interface/', views.onboarding_interest, name='onboarding_interest'),
    path('role-selection/', views.role_selection, name='role_selection'),
    path('company-onboarding/', views.company_onboarding, name='company_onboarding'),
    path('company-dashboard/', views.company_dashboard, name='company_dashboard'),
    path('register/', views.register, name='register'),
    path('email-sent/', views.email_sent, name='email_sent'),
    path('verify-email/<uidb64>/<token>/', views.verify_email, name='verify_email'),
    path('login/', auth_views.LoginView.as_view(template_name='users/login.html'), name='login'),
    path('logout/', auth_views.LogoutView.as_view(next_page='login'), name='logout'),
    path('profile/', views.profile, name='profile'),
    path('profile/edit/', views.edit_profile, name='edit_profile'),
    path('profile/upload-certificate/', views.upload_certificate, name='upload_certificate'),
    path('profile/delete-certificate/<int:certificate_id>/', views.delete_certificate, name='delete_certificate'),
    path('profile/<str:username>/', views.profile, name='user_profile'),
    path('inbox/', views.inbox, name='inbox'),
    path('chat/start/<str:username>/', views.start_chat, name='start_chat'),
    path('chat/<int:conversation_id>/', views.chat_detail, name='chat_detail'),
    path('chat/<int:conversation_id>/send/', views.send_message, name='send_message'),
    path('admin-access/', views.admin_access, name='admin_access'),
    path('custom-admin/', views.custom_admin_dashboard, name='custom_admin_dashboard'),
]
