# users/tasks.py

from .models import UserProfile

def background_update_preferences(user_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        user.update_preferences()
        print(f"Updated preferences for user {user.username}")
    except UserProfile.DoesNotExist:
        print(f"User with ID {user_id} not found")
