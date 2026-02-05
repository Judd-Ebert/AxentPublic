from django.db import models
from user_preferences.models import UserProfile
from product_recommender.models import Product
import uuid

class Wardrobe(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    product_ids = models.JSONField(default=list)

    class Meta:
        unique_together = ('user', 'name')

    def __str__(self):
        return f"{self.name} - {self.user.username}"


class WardrobeItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    wardrobe = models.ForeignKey(Wardrobe, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('wardrobe', 'product')

    def __str__(self):
        return f"{self.product.name} - {self.wardrobe.name}"