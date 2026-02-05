from rest_framework import viewsets, status
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Wardrobe, WardrobeItem
from .serializers import WardrobeSerializer, WardrobeItemSerializer
from rest_framework.decorators import action
from rest_framework import status
from firebase_admin import auth
from user_preferences.models import UserProfile
from user_preferences.recombee import client
from recombee_api_client.api_requests import AddBookmark, DeleteBookmark


class WardrobeViewSet(viewsets.ModelViewSet):
    authentication_classes = []
    permission_classes = []
    serializer_class = WardrobeSerializer
    

    def get_queryset(self):
    # Handle authentication
        auth_header = self.request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Wardrobe.objects.none()
        
        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        if not user_profile:
            return Wardrobe.objects.none()
        
        return Wardrobe.objects.filter(user=user_profile).prefetch_related(
            'items__product__images',
            'items__product__images360',
            'items__product__variants'
        )

    def list(self, request, *args, **kwargs):
        # Handle authentication
        print(f"Auth header received: {request.headers.get('Authorization')}")
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)
        
        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)
        
        # Now filter the queryset for this user with optimizations
        queryset = Wardrobe.objects.filter(user=user_profile).prefetch_related(
            'items__product__images',
            'items__product__images360',
            'items__product__variants'
        )
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    def create(self, request, *args, **kwargs):
        # Handle authentication
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)
        
        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)
        
        # Add the user to the request data
        data = request.data.copy()
        data['user'] = user_profile.id
        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer, user_profile)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer, user_profile):
        serializer.save(user=user_profile)

    @action(detail=False, methods=['get'])
    def list_by_user(self, request, *args, **kwargs):
        """List all wardrobes for a specific user"""
        # Handle authentication
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)
        
        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)
        
        # Get user ID from query parameters
        firebase_uid = request.query_params.get('firebase_uid')
        if not firebase_uid:
            return Response({"error": "firebase_uid parameter is required"}, status=400)
        
        try:
            user_profile = UserProfile.objects.get(firebase_uid=firebase_uid)
        except UserProfile.DoesNotExist:
            return Response({"error": "User not found"}, status=404)
        
        # Filter wardrobes for this user
        queryset = Wardrobe.objects.filter(user=user_profile).prefetch_related(
            'items__product__images',
            'items__product__images360',
            'items__product__variants'
        )
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def add_item(self, request, pk=None):
        # Handle authentication
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)

        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)

        wardrobe = get_object_or_404(Wardrobe, pk=pk, user=user_profile)

        # Add the wardrobe to the request data
        data = request.data.copy()
        data['wardrobe'] = wardrobe.id

        serializer = WardrobeItemSerializer(data=data)
        if serializer.is_valid():
            serializer.save(wardrobe=wardrobe)
            client.send(AddBookmark(user_profile.firebase_uid, data['product_id']))
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def remove_item(self, request, pk=None):
        # Handle authentication
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)
        
        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)
        
        # Get the wardrobe (only if it belongs to the user)
        wardrobe = get_object_or_404(Wardrobe, pk=pk, user=user_profile)
        
        product_id = request.data.get('product_id')
        if not product_id:
            return Response({'error': 'product_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        item = get_object_or_404(WardrobeItem, wardrobe=wardrobe, product_id=product_id)
        item.delete()
        client.send(DeleteBookmark(user_profile.firebase_uid, product_id))
        return Response(status=status.HTTP_204_NO_CONTENT)

def get_user_profile_from_token(token):
    """Helper function to get user profile from Firebase token"""
    try:
        decoded_token = auth.verify_id_token(token)
        firebase_uid = decoded_token['uid']
        return UserProfile.objects.get(firebase_uid=firebase_uid)
    except Exception as e:
        print(f"Error getting user from token: {e}")
        return None
