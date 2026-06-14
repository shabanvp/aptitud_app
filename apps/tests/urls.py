from django.urls import path
from . import views

urlpatterns = [
    path('arena/', views.arena_home, name='arena_home'),
    path('arena/practice/', views.practice_arena, name='practice_arena'),
    path('arena/practice/pdf/<str:filename>', views.serve_watermarked_pdf, name='serve_watermarked_pdf'),
    path('practice/', views.practice_dashboard, name='practice_dashboard'),
    path('practice/<slug:category_slug>/', views.start_test, name='start_test'),
    path('submit/', views.submit_test, name='submit_test'),

    # ── Flutter REST API ─────────────────────────────────────────
    path('api/tests/categories/', views.api_categories, name='api_categories'),
    path('api/tests/questions/', views.api_questions, name='api_questions'),
    path('api/tests/submit/', views.api_submit_answer, name='api_submit_answer'),
    path('api/tests/leaderboard/', views.api_leaderboard, name='api_leaderboard'),
    path('api/tests/stats/', views.api_user_stats, name='api_user_stats'),
]
