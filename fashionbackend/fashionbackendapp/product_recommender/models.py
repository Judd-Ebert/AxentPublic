from django.db import models
from django.contrib.auth.models import User
import uuid
from django.contrib.postgres.fields import ArrayField
from jsonschema import validate, ValidationError
from django.utils import timezone



class Product(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200, default="")
    brand = models.CharField(max_length=200, default="")
    model = models.CharField(max_length=200, null=True, blank=True)
    imageURL = models.URLField( max_length=500, default="")
    description = models.TextField(null=True, blank=True)
    sku = models.CharField(max_length=500, null=True, blank=True)
    slug = models.SlugField(unique=True, null=True, blank=True, max_length=300, help_text="Unique slug for the product")
    category = models.CharField(max_length=200, null=True, blank=True)
    secondary_category = models.CharField(max_length=200, null=True, blank=True)
    #Would be gallery - I think this is like a gallery of photos and i'll just use product Image for that
    upcoming = models.BooleanField(default=False, help_text="Indicates if the product is upcoming")
    #Again with gallery 360 - i might check for this later tho, maybe not a day 1 feature
    updated_at = models.DateTimeField(auto_now=False, default = timezone.now, null = True)
    link = models.URLField(default="", blank=True, help_text="Link to the product page", max_length=500)
    colorway = models.JSONField(default=list)
    normalized_colorway = models.JSONField(default=list)
    trait = models.BooleanField(default=False) #MEANS FEATURED?
    release_date = models.DateField(null=True, blank=True)
    retailprice = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    def __str__(self):
        return self.title
    
class ProductImage(models.Model): #Future versions, would like to utilize all images recieved
    product = models.ForeignKey(Product, related_name="images", on_delete=models.CASCADE)
    image_url = models.URLField( max_length=500) #Make arrayField if want > 1 image
    image_type = models.CharField(max_length=20, default="original")  # optional


    def __str__(self):
        return f"{self.product.title} - Image"

class ProductImage360(models.Model):
    product = models.ForeignKey(Product, related_name="images360", on_delete=models.CASCADE)
    image_url = models.URLField( max_length=500)
    order = models.IntegerField(default=0)  # To maintain the order of images

    def __str__(self):
        return f"{self.product.title} - 360 Image"


class ProductVariant(models.Model): #This is for the variants recieved from the API
    product = models.ForeignKey(Product, related_name="variants", on_delete=models.CASCADE)
    size = models.DecimalField(max_digits=3, decimal_places=1)
    isMen = models.BooleanField(default=True)
    isWomen = models.BooleanField(default=False)
    isYouth = models.BooleanField(default=False)
    isKids = models.BooleanField(default=False)
    lowest_ask = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    total_asks = models.IntegerField(default=0)
    previous_lowest_ask = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, help_text="Previous lowest ask price")
    
    subtotal = models.JSONField(
        default=dict,
        help_text="Dictionary of shipping options and their prices"
    )
    updated_at = models.DateTimeField(auto_now=False, default = timezone.now, null=True)
    