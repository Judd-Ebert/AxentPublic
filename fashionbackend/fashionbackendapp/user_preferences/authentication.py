"""
Custom authentication decorators and middleware for Firebase token validation
"""
from functools import wraps
from django.http import JsonResponse
from firebase_admin import auth
from user_preferences.models import UserProfile


def firebase_authenticated(view_func):
    """
    Decorator to ensure Firebase authentication for API endpoints
    """
    @wraps(view_func)
    def wrapped_view(request, *args, **kwargs):
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return JsonResponse({"error": "Invalid authorization header"}, status=401)
        
        token = auth_header.split(' ').pop()
        
        try:
            decoded_token = auth.verify_id_token(token)
            firebase_uid = decoded_token['uid']
            
            # Get or create user profile
            try:
                user_profile = UserProfile.objects.get(firebase_uid=firebase_uid)
            except UserProfile.DoesNotExist:
                email = decoded_token.get('email', '')
                name = decoded_token.get('name', '') or email.split('@')[0] if email else 'User'
                
                user_profile = UserProfile.objects.create(
                    firebase_uid=firebase_uid,
                    username=name,
                    email=email,
                )
            
            # Add user profile to request for easy access
            request.user_profile = user_profile
            return view_func(request, *args, **kwargs)
            
        except Exception as e:
            return JsonResponse({"error": "Invalid or expired token"}, status=401)
    
    return wrapped_view


def get_user_profile_from_request(request):
    """
    Extract user profile from request (if firebase_authenticated decorator is used)
    """
    return getattr(request, 'user_profile', None)
