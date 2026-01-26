from django.urls import path
from . import views

urlpatterns = [
    path('store/', views.store_view, name='store'),
    path('buy/<int:item_id>/', views.buy_item, name='buy_item'),
]
