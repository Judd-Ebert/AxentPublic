from django.core.management.base import BaseCommand
from product_recommender.models import ProductVariant
from decimal import Decimal, InvalidOperation
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = "Check and fix data integrity issues in ProductVariant table"

    def handle(self, *args, **options):
        self.stdout.write("Checking data integrity in ProductVariant table...")
        
        # Get all variants
        variants = ProductVariant.objects.all()
        total_variants = variants.count()
        self.stdout.write(f"Total variants: {total_variants}")
        
        problematic_variants = []
        
        for variant in variants:
            try:
                # Check if lowest_ask can be properly converted
                if variant.lowest_ask is not None:
                    # Try to convert to float to test
                    float(variant.lowest_ask)
                    
                # Check if previous_lowest_ask can be properly converted
                if variant.previous_lowest_ask is not None:
                    float(variant.previous_lowest_ask)
                    
            except (ValueError, TypeError, InvalidOperation) as e:
                problematic_variants.append({
                    'id': variant.id,
                    'product_id': variant.product_id,
                    'size': variant.size,
                    'lowest_ask': variant.lowest_ask,
                    'previous_lowest_ask': variant.previous_lowest_ask,
                    'error': str(e)
                })
        
        if problematic_variants:
            self.stdout.write(f"Found {len(problematic_variants)} problematic variants:")
            for pv in problematic_variants:
                self.stdout.write(f"  Variant {pv['id']}: {pv['error']}")
                self.stdout.write(f"    Product: {pv['product_id']}, Size: {pv['size']}")
                self.stdout.write(f"    lowest_ask: {pv['lowest_ask']} (type: {type(pv['lowest_ask'])})")
                self.stdout.write(f"    previous_lowest_ask: {pv['previous_lowest_ask']} (type: {type(pv['previous_lowest_ask'])})")
                
            # Fix problematic variants
            self.stdout.write("\nFixing problematic variants...")
            fixed_count = 0
            
            for pv in problematic_variants:
                try:
                    variant = ProductVariant.objects.get(id=pv['id'])
                    
                    # Fix lowest_ask
                    if variant.lowest_ask is not None:
                        try:
                            # Try to convert to Decimal
                            fixed_lowest_ask = Decimal(str(variant.lowest_ask))
                            variant.lowest_ask = fixed_lowest_ask
                        except (ValueError, TypeError, InvalidOperation):
                            # If conversion fails, set to None
                            variant.lowest_ask = None
                    
                    # Fix previous_lowest_ask
                    if variant.previous_lowest_ask is not None:
                        try:
                            # Try to convert to Decimal
                            fixed_previous_lowest_ask = Decimal(str(variant.previous_lowest_ask))
                            variant.previous_lowest_ask = fixed_previous_lowest_ask
                        except (ValueError, TypeError, InvalidOperation):
                            # If conversion fails, set to None
                            variant.previous_lowest_ask = None
                    
                    variant.save()
                    fixed_count += 1
                    self.stdout.write(f"  Fixed variant {pv['id']}")
                    
                except Exception as e:
                    self.stdout.write(f"  Error fixing variant {pv['id']}: {e}")
            
            self.stdout.write(f"Fixed {fixed_count} variants")
        else:
            self.stdout.write("No problematic variants found!")
        
        self.stdout.write("Data integrity check completed.") 