import datetime
import time
from time import sleep
from django.core.management.base import BaseCommand
import os
import requests
from decimal import Decimal
from product_recommender.models import Product, ProductImage, ProductImage360, ProductVariant
from recombee_api_client.api_requests import AddItemProperty, Batch, AddItem, SetItemValues
from ...recombee import client



#CURRENT: Got this command working and pulling from API, need to fill out things like url and images more

API_KEY = os.getenv("KICKSAPIKEY")

url = "https://api.kicks.dev/v3/stockx/products"

headers = {"Authorization": API_KEY}

LIMIT_PER_REQUEST = 100

PRODUCT_TOTAL = 10000

REQUEST_DELAY = 1.1

class Command(BaseCommand):
    help = "Import sneakers from kicks.dev into database"

    def handle(self, *args, **options):
        import time as time_module
        start_time = time_module.time()
        self.stdout.write("Starting product data import...")

        after_rank = 0
        total_imported = 0

        while total_imported < PRODUCT_TOTAL:
            params = {
                "limit":LIMIT_PER_REQUEST,
                "sort": "rank",
                "display[variants]":"true",
                "display[traits]":"true",
                "display[subtotal]":"true",
                "filters": f"product_type=\"sneakers\" AND rank > {after_rank}"
            }

            response = requests.get(url, headers=headers, params=params)
            if response.status_code != 200:
                self.stderr.write(f"Error fetching data: {response.status_code} - {response.text}")
                break

            data = response.json().get("data", [])


            if not data:
                self.stdout.write("No more products to import.")
                break

            self.stdout.write(f"API returned {len(data)} products")
            incoming_ids = [item.get("id") for item in data if item.get("id")]
            # Use select_related to reduce queries and prefetch_related for variants
            existing_products = Product.objects.filter(id__in=incoming_ids)
            existing_map = {str(p.id): p for p in existing_products}
            
            existing_variants_map = {
                (v.product_id, v.size, v.isMen): v
                for v in ProductVariant.objects.filter(product_id__in=[p.id for p in existing_products])
            }

            products_to_update = []
            products_to_create = []
            product_images = []
            product_images_360 = []
            variant_creates = []
            variant_updates = []

            recombee_list = []
                
            for product_data in data:
                product_id = product_data.get("id")
                if not product_id:
                    continue

                try:
                    product_sizes = []  # To track unique sizes across products
                    product_lowest_asks = []  # To track unique lowest asks across products
                    product_total_asks = []  # To track unique total asks across products
                    # -- product core data
                    title = product_data.get("title", "Unnamed Sneaker")
                    traits = {trait["trait"]: trait["value"] for trait in product_data.get("traits", [])}
                    existing = existing_map.get(product_id)
                    # Print the rank of each shoe as it's imported
                    rank = product_data.get("rank")
                    if existing:
                        product = existing
                        existing.title = title
                        existing.brand = product_data.get("brand", "")
                        existing.model = product_data.get("model", "")
                        gallery_360 = product_data.get("gallery_360", [])
                        if gallery_360:
                            existing.image = gallery_360[0]
                        else:
                            existing.imageURL = product_data.get("image", "")
                        existing.description = product_data.get("description", "")
                        existing.sku = product_data.get("sku")
                        existing.slug = product_data.get("slug")
                        existing.category = product_data.get("category")
                        existing.secondary_category = product_data.get("secondary_category")
                        existing.upcoming = product_data.get("upcoming", False)
                        existing.updated_at = safe_parse_datetime(product_data.get("updated_at"))
                        existing.link = product_data.get("link")
                        existing.colorway = parse_colorway(traits.get("Colorway"))
                        existing.normalized_colorway = parse_normalized_colorway(traits.get("Colorway"))
                        existing.trait = traits.get("Featured", "false").lower() == "true"
                        existing.release_date = safe_parse_datetime(traits.get("Release Date"))
                        existing.retailprice = safe_decimal(traits.get("Retail Price"))
                        products_to_update.append(existing)
                    else:
                        product = Product(
                            id=product_id,
                            title=title,
                            brand=product_data.get("brand", ""),
                            imageURL=product_data.get("gallery_360", [product_data.get("image", "")])[0] if product_data.get("gallery_360") else product_data.get("image", ""),
                            model=product_data.get("model", ""),
                            description=product_data.get("description", ""),
                            sku=product_data.get("sku"),
                            slug=product_data.get("slug"),
                            category=product_data.get("category"),
                            secondary_category=product_data.get("secondary_category"),
                            upcoming=product_data.get("upcoming", False),
                            updated_at=safe_parse_datetime(product_data.get("updated_at")),
                            link=product_data.get("link"),
                            colorway=parse_colorway(traits.get("Colorway")),
                            normalized_colorway=parse_normalized_colorway(traits.get("Colorway")),
                            trait=traits.get("Featured", "false").lower() == "true",
                            release_date=safe_parse_datetime(traits.get("Release Date")),
                            retailprice=safe_decimal(traits.get("Retail Price")),
                        )
                        products_to_create.append(product)
                    


                    # -- image (original)
                    image_url = product_data.get("image")
                    if image_url:
                        product_images.append(ProductImage(product=product, image_url=image_url, image_type="original"))

                    # -- 360 gallery
                    gallery_360 = product_data.get("gallery_360", [])
                    for index, img_url in enumerate(gallery_360, start=1):
                        product_images_360.append(ProductImage360(product=product, order=index, image_url=img_url))

                    # -- variants
                    for variant in product_data.get("variants", []):
                        size_type = variant.get("size_type", "").lower()
                        is_men = "m" in size_type or "men" in title.lower()
                        is_women = "w" in size_type or "women" in title.lower()
                        is_youth = "y" in size_type or "youth" in title.lower()
                        is_kids = "k" in size_type or "c" in size_type or "kids" in title.lower() or "children" in title.lower()
                        raw_size = variant.get("size", "").lower().strip()

                        if "w" in raw_size:
                            cleaned_size = raw_size.replace("w", "")
                            is_women = True
                        elif "y" in raw_size:
                            cleaned_size = raw_size.replace("y", "")
                            is_youth = True
                        elif "k" in raw_size or "c" in raw_size:
                            cleaned_size = raw_size.replace("k", "").replace("c", "")
                            is_kids = True
                        else:
                            cleaned_size = raw_size

                        variant_size = safe_decimal(cleaned_size)
                        if variant_size is None:
                            continue

                        key = (product_id, variant_size, is_men)
                        if key in existing_variants_map:
                            variant_obj = existing_variants_map[key]
                            variant_obj.lowest_ask = safe_decimal(variant.get("lowest_ask"))
                            variant_obj.total_asks = variant.get("total_asks") or 0
                            variant_obj.previous_lowest_ask = safe_decimal(variant.get("previous_lowest_ask"))
                            variant_obj.subtotal = variant.get("subtotal", {})
                            variant_obj.updated_at = safe_parse_datetime(variant.get("updated_at"))
                            variant_updates.append(variant_obj)
                        else:
                            variant_creates.append(ProductVariant(
                                product=product,
                                size=variant_size,
                                isMen=is_men,
                                isWomen=is_women,
                                isYouth=is_youth,
                                isKids=is_kids,
                                lowest_ask=safe_decimal(variant.get("lowest_ask")),
                                total_asks=variant.get("total_asks") or 0,
                                previous_lowest_ask=safe_decimal(variant.get("previous_lowest_ask")),
                                subtotal=variant.get("subtotal", {}),
                                updated_at=safe_parse_datetime(variant.get("updated_at")),
                            ))
                        
                        # Send all sizes, with 0 for sizes that have no lowest ask data
                        raw_lowest_ask = variant.get("lowest_ask")
                        processed_lowest_ask = float(raw_lowest_ask or 0)
                        
                        product_sizes.append(float(variant_size))
                        product_lowest_asks.append(processed_lowest_ask)
                        product_total_asks.append(int(variant.get("total_asks") or 0))
                    
                    recombee_list.append(SetItemValues(
                        item_id=str(product.id),
                        values={
                            "Image": product.imageURL, #Picture
                            "title": product.title,
                            "brand": product.brand,
                            "model":  product.model,
                            "imageURL": product.imageURL, #URL
                            "description": product.description,
                            "sku": product.sku,
                            "slug": product.slug,
                            "category": product.category,
                            "secondary_category": product.secondary_category,
                            "upcoming": product.upcoming,
                            "updated_at": product.updated_at.isoformat() if product.updated_at else None,
                            "link": product.link,
                            "colorway": product.colorway,
                            "normalized_colorway": product.normalized_colorway,
                            "trait": product.trait,
                            "release_date": product.release_date.isoformat() if product.release_date else None,
                            "retailprice": float(product.retailprice) if product.retailprice else None,
                            "sizes_available": product_sizes,
                            "lowest_ask": product_lowest_asks,
                            "total_asks": product_total_asks,
                            "isMen": is_men,
                            "isWomen": is_women,
                            "isYouth": is_youth,
                            "isKids": is_kids,
                        },
                        cascade_create=True
                    ))


                    total_imported += 1

                except Exception as e:
                    self.stderr.write(f"⚠️ Error processing product {product_id}: {e}")
                    continue

            # Check if we've reached the total limit after processing the full batch
            if total_imported >= PRODUCT_TOTAL:
                break

            # Debug summary for this batch
            self.stdout.write(f"📊 Batch summary: {len(products_to_create)} to create, {len(products_to_update)} to update, {len(recombee_list)} for Recombee")

            # Save all at once with error handling
            try:
                if products_to_create:
                    created_products = Product.objects.bulk_create(products_to_create)
                    self.stdout.write(f"✅ Created {len(created_products)} new products")
                
                if product_images:
                    created_images = ProductImage.objects.bulk_create(product_images)
                    self.stdout.write(f"✅ Created {len(created_images)} product images")
                
                if product_images_360:
                    created_images_360 = ProductImage360.objects.bulk_create(product_images_360)
                    self.stdout.write(f"✅ Created {len(created_images_360)} 360 images")
                
                if variant_creates:
                    created_variants = ProductVariant.objects.bulk_create(variant_creates)
                    self.stdout.write(f"✅ Created {len(created_variants)} variants")
                
                if products_to_update:
                    updated_count = Product.objects.bulk_update(products_to_update, [
                        "title", "brand", "model", "description", "slug", "category",
                        "secondary_category", "upcoming", "updated_at", "link", "colorway", "normalized_colorway",
                        "trait", "release_date", "retailprice"
                    ])
                    self.stdout.write(f"✅ Updated {updated_count} products")
                
                if variant_updates:
                    updated_variants_count = ProductVariant.objects.bulk_update(
                        variant_updates,
                        ["lowest_ask", "total_asks", "previous_lowest_ask", "subtotal", "updated_at"]
                    )
                    self.stdout.write(f"✅ Updated {updated_variants_count} variants")
                    
            except Exception as e:
                self.stderr.write(f"❌ Database save error: {e}")
                # Don't send to Recombee if database save failed
                recombee_list.clear()
                continue

            if recombee_list:
                try:
                    client.send(Batch(recombee_list))
                    self.stdout.write(self.style.SUCCESS(f"✅ Recombee batch sent for {len(recombee_list)} items."))
                except Exception as e:
                    self.stderr.write(f"❌ Error sending Recombee batch: {e}")
                recombee_list.clear()

            after_rank = data[-1].get("rank")
            
            self.stdout.write(f"Imported up to rank {after_rank - 1} ({total_imported} total)")

            product_images.clear()
            product_images_360.clear()
            variant_creates.clear()
            variant_updates.clear()
            products_to_create.clear()
            products_to_update.clear()


        end_time = time_module.time()
        duration = end_time - start_time
        rate = total_imported / duration if duration > 0 else 0
        self.stdout.write(self.style.SUCCESS(f"Finished importing {total_imported} products in {duration:.2f} seconds ({rate:.2f} products/second)."))         



from decimal import Decimal, InvalidOperation

def safe_decimal(value):
    try:
        return Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        return None

from django.utils.dateparse import parse_datetime

def safe_parse_datetime(value):
    if isinstance(value, str):
        return parse_datetime(value)
    return None

import re

color_keywords = {
    "black": [
        "black", "bred", "noir", "anthracite", "onyx", "obsidian", "phantom", "stealth", "iron", "ebony", "carbon", "core black", "utility black", "off noir", "shadow", "dark smoke", "pitch", "charcoal", "graphite", "smoke", "jet", "ink"
    ],
    "white": [
        "white", "sail", "cream", "ivory", "off white", "pure platinum", "summit white", "egret", "bone", "chalk", "cloud", "paper white", "snow", "pearl", "natural", "vanilla", "milk", "alabaster"
    ],
    "grey": [
        "grey", "gray", "cool grey", "wolf grey", "cement", "ash", "platinum", "pewter", "dove", "ironstone", "flint", "smoke grey", "light smoke grey", "medium grey", "dark grey", "steel", "slate", "granite", "marina", "graphite grey", "open grey", "silver", "chrome"
    ],
    "red": [
        "red", "university red", "varsity red", "team red", "infrared", "crimson", "scarlet", "burgundy", "maroon", "rose", "fire red", "lava", "habanero red", "gym red", "picante red", "bordeaux", "wine", "brick", "rust", "ember", "pomegranate"
    ],
    "blue": [
        "blue", "royal", "navy", "obsidian", "aqua", "turquoise", "teal", "cyan", "azure", "indigo", "midnight navy", "university blue", "game royal", "legend blue", "photo blue", "racer blue", "deep royal", "hyper cobalt", "kentucky", "carolina", "powder blue", "ice blue", "glacier", "ocean", "denim", "cobalt", "sky", "storm blue", "dark powder blue", "blue void"
    ],
    "green": [
        "green", "pine", "forest", "olive", "army", "sage", "mint", "jade", "aqua", "teal", "volt", "lucky green", "bamboo", "chlorophyll", "malachite", "moss", "pistachio", "seafoam", "neptune", "turbo green", "cargo", "camo", "camouflage", "parachute"
    ],
    "yellow": [
        "yellow", "maize", "lemon", "gold", "mustard", "tour yellow", "taxi", "citrus", "sulfur", "wheat", "amber", "banana", "canary", "sun", "illuminating", "lightning", "pollen", "ochre", "straw", "honey", "butter"
    ],
    "orange": [
        "orange", "magma", "rust", "peach", "coral", "copper", "pumpkin", "sunset", "apricot", "tangerine", "safety orange", "ember", "cinnabar", "firewood", "burnt", "solar orange", "laser orange", "harvest moon"
    ],
    "brown": [
        "brown", "mocha", "chocolate", "taupe", "beige", "tan", "earth", "fossil", "pecan", "cacao", "coffee", "camel", "sand", "sesame", "burlap", "timber", "timberwolf", "flax", "mushroom", "oatmeal", "linen", "stone", "driftwood", "hazel", "caramel", "gum", "vachetta", "palomino"
    ],
    "pink": [
        "pink", "rose", "blush", "bubblegum", "fuchsia", "magenta", "coral", "lotus", "barely rose", "hot pink", "fireberry", "strawberry", "salmon", "peach", "pale pink", "rose whisper", "rose tone", "regal pink", "rose gold"
    ],
    "purple": [
        "purple", "violet", "lilac", "plum", "eggplant", "amethyst", "lavender", "orchid", "grape", "deep orchid", "psychic purple", "court purple", "hyper grape", "concord", "dark iris"
    ],
    "beige": [
        "beige", "cream", "ivory", "sand", "linen", "oat", "almond", "khaki", "pale vanilla", "light bone", "sesame", "stone", "natural", "flax", "wheat", "muslin"
    ],
    "metallic": [
        "metallic", "chrome", "silver", "gold", "pewter", "bronze", "copper", "platinum", "iridescent", "foil", "shimmer", "sparkle"
    ],
    "multicolor": [
        "multicolor", "multi-color", "rainbow", "tie-dye", "gradient", "mashup", "mix", "print", "color", "what the", "patchwork", "prism"
    ],
    "neon": [
        "neon", "volt", "glow", "hyper", "bright", "fluorescent", "solar", "electric", "infrared", "highlighter"
    ]
}

def parse_colorway(raw_value):
    if not raw_value:
        return []
    try:
        cleaned = re.sub(r'[\/\-]', ',', raw_value)
        parts = [part.strip().title() for part in cleaned.split(',') if part.strip()]
        return list(dict.fromkeys(parts))

    except Exception as e:
        print(f"Error parsing colorway: {e}")
        return []

def parse_normalized_colorway(raw_value):
    if not raw_value:
        return []
    try:
        cleaned = re.sub(r'[\/\-]', ',', raw_value)
        parts = [part.strip().lower() for part in cleaned.split(',') if part.strip()]
        found_colors = set()

        for part in parts:
            for core_color, keywords in color_keywords.items():
                for keyword in keywords:
                    if keyword in part:
                        found_colors.add(core_color)
                        break  # stop checking other keywords for this part
        return list(found_colors)
    except Exception as e:
        print(f"Error parsing normalized colorway: {e}")
        return []