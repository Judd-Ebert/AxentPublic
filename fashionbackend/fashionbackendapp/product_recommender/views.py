from .models import Product, ProductVariant, User
from rest_framework.decorators import action, authentication_classes
from rest_framework.response import Response
from rest_framework import viewsets, status
from .serializer import ProductSerializer, ProductImageSerializer
from firebase_admin import auth as firebase_auth
from user_preferences.models import UserProfile
from user_preferences.recombee import client
from recombee_api_client.api_requests import RecommendItemsToUser, RecommendNextItems

# In user_preferences/utils.py or at the top of views.py
from firebase_admin import auth as firebase_auth

RECOMMENDATION_AMOUNT = 3

def get_user_from_token(token):
    try:
        decoded_token = firebase_auth.verify_id_token(token)
        firebase_uid = decoded_token['uid']
        return UserProfile.objects.get(firebase_uid=firebase_uid)
    except Exception as e:
        print(f"Error getting user from token: {e}")
        return None

class ProductViewSet(viewsets.ViewSet):
    authentication_classes = []
    permission_classes = []
    
    def get_queryset(self):
        return Product.objects.all()


    @action(detail=False, methods=['get'])
    def search(self, request):
        """
        Search for products by name
        """
        query = request.query_params.get('q', '')
        if not query:
            return Response([], status=status.HTTP_200_OK)
        
        results = Product.objects.filter(name__icontains=query)[:10]
        serializer = ProductSerializer(results, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=[''])
    def recommend(self, request):
        """Get product recommendations for a user"""
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)
        token = auth_header.split(' ').pop()
        user_profile = get_user_from_token(token)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)
        try:
            filters = request.query_params.get('filters')
            print(filters)
            if not isinstance(filters, str):
                filters = ''
        except KeyError:
            return Response({"error": "Filters not provided"}, status=400)
            
        
        recommId = request.query_params.get('recommId')
        
        try:
            if filters != '' and recommId == '': #Filters, no ID
                print("New Recommendations")
                recommendations = client.send(RecommendItemsToUser(user_profile.firebase_uid, RECOMMENDATION_AMOUNT, filter=filters))
            elif filters != '' and recommId != '': #Filters, ID
                print("Next Recommendations")
                recommendations = client.send(RecommendNextItems(recommId, RECOMMENDATION_AMOUNT))
            elif filters == '' and recommId == '': #No Filters, no ID
                print("New Recommendations")
                recommendations = client.send(RecommendItemsToUser(user_profile.firebase_uid, RECOMMENDATION_AMOUNT))
            elif filters == '' and recommId != '': #No Filters, ID
                print("Next Recommendations")
                recommendations = client.send(RecommendNextItems(recommId, RECOMMENDATION_AMOUNT))
            print(recommendations)
            product_ids = [rec['id'] for rec in recommendations['recomms']]
            if not product_ids:
                print("⚠️ No valid product variants matched filter criteria or Recombee returned unknown IDs.")
                return Response([], status=200)
            sizes = extract_sizes(filters)
            if sizes:
                price_range = extract_price_range(filters)
                valid_product_ids = []
                for product_id in product_ids:
                    for size in sizes:
                        try:
                            product = ProductVariant.objects.get(product_id=product_id, size=size)
                            if (price_range['min'] is not None and
                            price_range['max'] is not None and
                            product.previous_lowest_ask is not None and
                            price_range['min'] <= product.previous_lowest_ask <= price_range['max']):
                                valid_product_ids.append(product_id)
                        except ProductVariant.DoesNotExist:
                            continue
                product_ids = valid_product_ids
            products = Product.objects.filter(id__in=product_ids)
            serializer = ProductSerializer(products, many=True)
            # Include recommId in response if it exists
            response_data = {
                'products': serializer.data,
                'recommId': recommendations.get('recommId') if 'recommId' in recommendations else None
            }
            return Response(response_data)
        except Exception as e:
            print(f"Error getting recommendations: {e}")
            return Response([], status=status.HTTP_500_INTERNAL_SERVER_ERROR)


import re

def extract_sizes(filters):
    sizes = []
    if not filters:
        return sizes
    
    # Look for patterns like: 'sizes_available' ANY [8 OR 9 OR 10]
    match = re.search(r"'sizes_available'\s*ANY\s*\[([\d\sOR]+)\]", filters)
    if match:
        # Extract the numbers from the match
        sizes_str = match.group(1)
        # Split by 'OR' and clean up the values
        sizes = [s.strip() for s in sizes_str.split('OR') if s.strip()]
    
    return sizes

def extract_price_range(filters):
    price_range = {'min': None, 'max': None}
    if not filters:
        return price_range
    
    # Look for patterns like: 'retailprice' >= 20 AND 'retailprice' <= 80
    match = re.search(r"'retailprice'\s*>=\s*([\d.]+)\s*AND\s*'retailprice'\s*<=\s*([\d.]+)", filters)
    if match:
        price_range['min'] = float(match.group(1))
        price_range['max'] = float(match.group(2))
    
    return price_range