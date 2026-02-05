#Converts HTTP Request data to Python data types and vice versa, basically just making the requests something django can understand
from .models import Product, ProductImage, ProductVariant, ProductImage360
from rest_framework import serializers
from django.db.models import Min
import logging

logger = logging.getLogger(__name__)

class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['image_url', 'image_type']

class ProductImage360Serializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage360
        fields = ['image_url', 'order']

class ProductVariantSerializer(serializers.ModelSerializer):
    lowest_ask = serializers.SerializerMethodField()
    
    class Meta:
        model = ProductVariant
        fields = ['size', 'isMen', 'isWomen', 'isYouth', 'isKids', 'lowest_ask', 'total_asks', 'previous_lowest_ask', 'subtotal', 'updated_at']
    
    def get_lowest_ask(self, obj):
        try:
            if obj.lowest_ask is not None:
                return float(obj.lowest_ask)
            return None
        except (ValueError, TypeError) as e:
            logger.error(f"Error converting lowest_ask for variant {obj.id}: {e}")
            return None

class ProductSerializer(serializers.ModelSerializer):
    images = ProductImageSerializer(many=True, read_only=True)  # Nested serializer
    images360 = ProductImage360Serializer(many=True, read_only=True)
    variants = ProductVariantSerializer(many=True, read_only=True)
    lowest_ask = serializers.SerializerMethodField()
    size_lowest_asks = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = ['id','title','brand','model','description','sku','slug','category','secondary_category','upcoming','updated_at','link','colorway','trait','release_date','retailprice', 'images', 'images360', 'variants', 'lowest_ask', 'size_lowest_asks']
    
    def get_lowest_ask(self, obj):
        try:
            # Get the lowest ask across all variants
            variants_with_asks = obj.variants.filter(lowest_ask__isnull=False).exclude(lowest_ask=0)
            if variants_with_asks.exists():
                min_ask = variants_with_asks.aggregate(Min('lowest_ask'))['lowest_ask__min']
                if min_ask is not None:
                    return float(min_ask)
            return None
        except Exception as e:
            logger.error(f"Error calculating lowest_ask for product {obj.id}: {e}")
            return None
    
    def get_size_lowest_asks(self, obj):
        try:
            # Get size-specific lowest ask data (only include sizes with actual pricing)
            size_lowest_asks = {}
            variants = obj.variants.filter(lowest_ask__isnull=False).exclude(lowest_ask=0)
            
            for variant in variants:
                try:
                    if variant.lowest_ask and variant.lowest_ask > 0:
                        size_lowest_asks[str(variant.size)] = float(variant.lowest_ask)
                except (ValueError, TypeError) as e:
                    logger.error(f"Error processing variant {variant.id} for product {obj.id}: {e}")
                    continue
            
            return size_lowest_asks
        except Exception as e:
            logger.error(f"Error calculating size_lowest_asks for product {obj.id}: {e}")
            return {}