from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from multiplayer import views as multiplayer_views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('users.urls')),
    path('tests/', include('apps.tests.urls')),
    path('', include('apps.tests.urls')),      # exposes /api/tests/* at root level
    path('gamification/', include('gamification.urls')),
    path('events/', include('events.urls')),
    path('api/multiplayer/topics/', multiplayer_views.api_topics, name='api_multiplayer_topics'),
    path('multiplayer/', include('multiplayer.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
