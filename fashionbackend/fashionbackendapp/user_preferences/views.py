from django.shortcuts import get_object_or_404
from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.decorators import api_view, action
from rest_framework.throttling import UserRateThrottle, AnonRateThrottle
from django_ratelimit.decorators import ratelimit
from django.utils.decorators import method_decorator
from firebase_admin import auth
from .models import Product, UserPreference, UserProfile
from product_recommender.serializer import ProductSerializer
from .recombee import client
from recombee_api_client.api_requests import AddUser, AddRating, AddDetailView, AddPurchase, DeleteUser, SetUserValues
import os


def get_user_profile_from_token(token):
    """Helper function to get user profile from Firebase token"""
    try:
        decoded_token = auth.verify_id_token(token)
        firebase_uid = decoded_token['uid']
        
        try:
            user_profile = UserProfile.objects.get(firebase_uid=firebase_uid)
            return user_profile
        except UserProfile.DoesNotExist:
            # Create a new user profile if it doesn't exist
            email = decoded_token.get('email', '')
            name = decoded_token.get('name', '') or email.split('@')[0] if email else 'User'
            
            user_profile = UserProfile.objects.create(
                firebase_uid=firebase_uid,
                username=name,
                email=email,
            )
            return user_profile
            
    except Exception as e:
        print(f"Error getting user from token: {e}")
        return None


class UserPreferenceViewSet(viewsets.ViewSet):
    authentication_classes = []
    permission_classes = []
    throttle_classes = [UserRateThrottle, AnonRateThrottle]

    def get_user_from_request(self, request):
        """Helper method to get user from request token"""
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return None
        
        token = auth_header.split(' ').pop()
        return get_user_profile_from_token(token)


    @action(detail=False, methods=['post'])
    @method_decorator(ratelimit(key='user', rate='10000/h', method='POST'))
    def handle_swipe(self, request):
        user_profile = self.get_user_from_request(request)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)

        try:
            product_id = request.data.get('product_id')
            preference_value = int(request.data.get('preference', 0))
            recomm_id = request.data.get('recomm_id', '')
            product = get_object_or_404(Product, id=product_id)
            
            UserPreference.objects.update_or_create(
                user=user_profile,
                product=product,
                defaults={'preference': preference_value}
            )

            if preference_value == 1:
                user_profile.liked_products.add(product)
            
            user_profile.save()

            try:
                if recomm_id != '':
                    client.send(AddRating(user_profile.firebase_uid, product_id, preference_value, recomm_id=recomm_id))
                else:
                    client.send(AddRating(user_profile.firebase_uid, product_id, preference_value))
            except Exception as recombee_error:
                print(f"Recombee error: {recombee_error}")
            

            return Response({'message': 'Preference updated successfully'})

        except Exception as e:
            print(f"Error in handle_swipe: {str(e)}")
            return Response({'error': 'Server error occurred'}, status=500)

    @action(detail=False, methods=['get'])
    def liked_products(self, request):
        try:
            auth_header = request.headers.get('Authorization', '')
            if not auth_header.startswith('Bearer '):
                return Response({"error": "Invalid authorization header"}, status=401)

            token = auth_header.split(' ').pop()
            user_profile = get_user_profile_from_token(token)
            if not user_profile:
                return Response({"error": "Invalid or expired token"}, status=401)
            
            # Get liked products with optimized queries and pagination
            try:
                page = int(request.GET.get('page', 1))
                page_size = int(request.GET.get('page_size', 20))  # Limit to 20 products per page
                
                # Use only() to limit fields and reduce memory usage
                products = user_profile.liked_products.select_related().prefetch_related(
                    'images',
                    'images360',
                    'variants'
                ).only(
                    'id', 'title', 'brand', 'model', 'description', 'sku', 'slug',
                    'category', 'secondary_category', 'upcoming', 'updated_at',
                    'link', 'colorway', 'trait', 'release_date', 'retailprice'
                ).all()
                
                total_count = products.count()
                
                # Apply pagination
                start = (page - 1) * page_size
                end = start + page_size
                paginated_products = products[start:end]
                
                # Serialize with error handling
                serializer = ProductSerializer(paginated_products, many=True)
                
                return Response({
                    'products': serializer.data,
                    'pagination': {
                        'page': page,
                        'page_size': page_size,
                        'total_count': total_count,
                        'total_pages': (total_count + page_size - 1) // page_size
                    }
                })
                
            except Exception as e:
                print(f"Error serializing liked products: {e}")
                # Return empty list if serialization fails
                return Response({'products': [], 'pagination': {'page': 1, 'page_size': 20, 'total_count': 0, 'total_pages': 0}})
                
        except Exception as e:
            print(f"Error in liked_products endpoint: {e}")
            return Response({"error": "Server error occurred"}, status=500)

    @action(detail=False, methods=['get'])
    def bought_products(self, request):
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)

        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)
        
        products = user_profile.bought_products.all()
        serializer = ProductSerializer(products, many=True)
        return Response(serializer.data)


    @action(detail=False, methods=['post'])
    def update_bought_product(self, request):
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)

        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)

        try:
            product_ids = request.data.get('product_ids', [])
            user_profile.bought_products.add(*product_ids)
            return Response({"message": "Bought products updated successfully"})
        except Exception as e:
            print(f"Error updating bought products: {e}")
            return Response({"error": "Failed to update bought products"}, status=500)

    @action(detail=False, methods=['post'])
    @method_decorator(ratelimit(key='user', rate='5/m', method='POST'))
    def create_user(self, request):
        print('Creating user')
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)
        
        token = auth_header.split(' ').pop()
        
        try:
            decoded_token = auth.verify_id_token(token)
            uid = decoded_token['uid']
            email = decoded_token.get('email')
            name = request.data.get('name', '')

            # Create or update the UserProfile with Firebase UID + name
            profile, profile_created = UserProfile.objects.get_or_create(
                firebase_uid=uid,
                defaults={
                    'username': name,
                    'email': email,
                }
            )

            if not profile_created:
                # If profile already exists, update it
                profile.firebase_uid = uid
                profile.name = name
                profile.save()
            # Create Recombee user
            print("lebronza")
            
            print("RECOMBEE_DATABASE_ID:", os.getenv('RECOMBEE_DATABASE_ID'))
            print("RECOMBEE_PRIVATE_TOKEN:", os.getenv('RECOMBEE_PRIVATE_TOKEN'))
            try:
                client.send(AddUser(uid))
            except Exception as e:
                print(f"Error creating user: {e}")

            return Response({
                'message': 'User and profile created successfully' if profile_created else 'User already exists'
            })

        except auth.InvalidIdTokenError:
            return Response({'error': 'Invalid ID token'}, status=400)
        except Exception as e:
            print(f"Error creating user: {e}")
            return Response({'error': 'Server error'}, status=500)

    def user_profile(self, request):
        """Check if user profile exists in backend"""
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)
        
        token = auth_header.split(' ').pop()
        
        try:
            decoded_token = auth.verify_id_token(token)
            uid = decoded_token['uid']
            
            # Check if user profile exists
            try:
                profile = UserProfile.objects.get(firebase_uid=uid)
                return Response({
                    'exists': True,
                    'user_id': uid,
                    'username': profile.username,
                    'email': profile.email
                })
            except UserProfile.DoesNotExist:
                return Response({
                    'exists': False,
                    'user_id': uid
                }, status=404)
                
        except auth.InvalidIdTokenError:
            return Response({'error': 'Invalid ID token'}, status=401)
        except Exception as e:
            print(f"Error checking user profile: {e}")
            return Response({'error': 'Server error'}, status=500)

    @action(detail=False, methods=['post'])
    def post_detail_view(self, request):
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)

        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)
        
        product_id = request.data.get('product_id')
        if not product_id:
            return Response({"error": "Product ID is required"}, status=400)

        try:
            client.send(AddDetailView(user_profile.firebase_uid, product_id))
            return Response({"message": "Detail view recorded successfully"})
        except Exception as e:
            print(f"Error sending detail view: {e}")
            return Response({"error": "Failed to record detail view"}, status=500)

    @action(detail=False, methods=['post'])
    def buy_product(self, request):
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)
        
        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)
        
        product_id = request.data.get('product_id')
        if not product_id:
            return Response({"error": "Product ID is required"}, status=400)
        
        try:
            client.send(AddPurchase(user_profile.firebase_uid, product_id))
            return Response({"message": "Purchase recorded successfully"})
        except Exception as e:
            print(f"Error sending purchase: {e}")
            return Response({"error": "Failed to record purchase"}, status=500)

    @action(detail=False, methods=['delete'])
    @method_decorator(ratelimit(key='user', rate='2/m', method='DELETE'))
    def delete_account(self, request):
        """Permanently delete user account from all systems"""
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)
        
        token = auth_header.split(' ').pop()
        
        try:
            # Verify Firebase token
            decoded_token = auth.verify_id_token(token)
            firebase_uid = decoded_token['uid']
            
            # Get user profile
            try:
                user_profile = UserProfile.objects.get(firebase_uid=firebase_uid)
            except UserProfile.DoesNotExist:
                return Response({"error": "User profile not found"}, status=404)
            
            # 1. Delete from Recombee
            try:
                client.send(DeleteUser(firebase_uid))
            except Exception as e:
                print(f"Error deleting user from Recombee: {e}")
                # Continue with deletion even if Recombee fails
            
            # 2. Delete from Firebase
            try:
                auth.delete_user(firebase_uid)
            except Exception as e:
                print(f"Error deleting user from Firebase: {e}")
                # Continue with database deletion even if Firebase fails
            
            # 3. Delete from database (this will cascade delete related preferences)
            user_profile.delete()
            
            return Response({
                "message": "Account successfully deleted from all systems"
            }, status=200)
            
        except auth.InvalidIdTokenError:
            return Response({"error": "Invalid or expired token"}, status=401)
        except Exception as e:
            print(f"Error deleting account: {e}")
            return Response({"error": "Failed to delete account"}, status=500)


    def product_detail(self, request, product_id=None):
        try:
            product = Product.objects.get(id=product_id)
            serializer = ProductSerializer(product)
            
            # Get user from token for AddDetailView
            auth_header = request.headers.get('Authorization', '')
            if not auth_header.startswith('Bearer '):
                return Response({"error": "Invalid authorization header"}, status=401)

            token = auth_header.split(' ').pop()
            user_profile = get_user_profile_from_token(token)
            if not user_profile:
                return Response({"error": "Invalid or expired token"}, status=401)
            
            return Response(serializer.data)
        except Product.DoesNotExist:
            return Response({"error": "Product not found"}, status=404)

    def set_initial_preferences(self, request):
        """Set initial user preferences during onboarding"""
        try:
            # Get user from token
            auth_header = request.headers.get('Authorization', '')
            if not auth_header.startswith('Bearer '):
                return Response({"error": "Invalid authorization header"}, status=401)

            token = auth_header.split(' ').pop()
            user_profile = get_user_profile_from_token(token)
            if not user_profile:
                return Response({"error": "Invalid or expired token"}, status=401)

            # Extract preferences from request
            data = request.data
            initial_budget_min = data.get('InitialBudgetMin', 0)
            initial_budget_max = data.get('InitialBudgetMax', 500)
            initial_gender = data.get('InitialGender', '')
            initial_preferred_brands = data.get('InitialPreferredBrands', [])
            initial_sizes = data.get('InitialSizes', [])

            # Validate required fields
            if not initial_gender or not initial_preferred_brands or not initial_sizes:
                return Response({
                    "error": "Missing required fields: InitialGender, InitialPreferredBrands, or InitialSizes"
                }, status=400)

            # Send to Recombee using SetUserValues
            try:
                user_id = user_profile.firebase_uid
                
                # Prepare user values for Recombee
                user_values = {
                    'InitialBudgetMin': float(initial_budget_min),
                    'InitialBudgetMax': float(initial_budget_max),
                    'InitialGender': str(initial_gender),
                    'InitialPreferredBrands': initial_preferred_brands,  # Recombee supports arrays
                    'InitialSizes': initial_sizes,  # Recombee supports arrays
                }
                
                # Send to Recombee
                client.send(SetUserValues(
                    user_id=user_id,
                    values=user_values
                ))
                
                return Response({
                    "message": "Initial preferences saved successfully",
                    "user_id": user_id
                }, status=200)
                
            except Exception as recombee_error:
                print(f"Error sending to Recombee: {recombee_error}")
                return Response({
                    "error": "Failed to save preferences to recommendation system",
                    "details": str(recombee_error)
                }, status=500)
                
        except auth.InvalidIdTokenError:
            return Response({"error": "Invalid or expired token"}, status=401)
        except Exception as e:
            print(f"Error setting initial preferences: {e}")
            return Response({
                "error": "Failed to save initial preferences",
                "details": str(e)
            }, status=500)

@api_view(['GET'])
def health_check(request):
    """Simple health check endpoint"""
    return Response({"status": "healthy", "message": "Backend is running"})
