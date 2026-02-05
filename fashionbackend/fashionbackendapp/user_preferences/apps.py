from django.apps import AppConfig


class UserPreferencesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'user_preferences'

    def ready(self):
        # Import signals
        from .signals import create_or_update_user_profile
        # Initialize Firebase
        from .firebase import initialize_firebase
        initialize_firebase()
