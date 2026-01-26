from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from .models import StoreItem, UserItem

@login_required
def store_view(request):
    items = StoreItem.objects.all()
    # Get user inventory IDs
    inventory_ids = UserItem.objects.filter(user=request.user).values_list('item_id', flat=True)
    return render(request, 'gamification/store.html', {'items': items, 'inventory_ids': inventory_ids})

@login_required
def buy_item(request, item_id):
    if request.method == 'POST':
        item = get_object_or_404(StoreItem, id=item_id)
        user = request.user
        
        if user.coins >= item.cost:
            if item.item_type == 'LIFE_REFILL':
                if user.lives >= 5:
                    messages.warning(request, "Your lives are already full.")
                else:
                    user.coins -= item.cost
                    user.lives = 5
                    user.save()
                    messages.success(request, "Lives fully refilled!")
            else:
                if UserItem.objects.filter(user=user, item=item).exists():
                    messages.info(request, "You already own this item.")
                else:
                    user.coins -= item.cost
                    user.save()
                    UserItem.objects.create(user=user, item=item)
                    messages.success(request, f"Successfully purchased {item.name}!")
        else:
            messages.error(request, "Not enough coins.")
            
    return redirect('store')
