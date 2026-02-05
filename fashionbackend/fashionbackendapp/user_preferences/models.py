from django.db import models
from django.contrib.auth.models import User
from product_recommender.models import Product, ProductImage


class UserProfile(models.Model):
    """Stores aggregated preferences for fast ML access"""
    username = models.CharField(max_length=150, default="")
    email = models.EmailField(default="")
    firebase_uid = models.CharField(max_length=256, unique=True)
    liked_products = models.ManyToManyField(Product, related_name="liked_by", blank=True)
    bought_products = models.ManyToManyField(Product, related_name="bought_by", blank=True)

    def update_preferences(self):
        """Recalculates and stores user preferences from UserPreference"""
        user_prefs = UserPreference.objects.filter(user=self).values("product_id", "preference")
        self.preferences = {str(p["product_id"]): p["preference"] for p in user_prefs}
        self.save()

    def __str__(self):
        return f"Profile for {self.username}"

    

class UserPreference(models.Model):
    """Stores individual user-product interactions"""
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    preference = models.IntegerField(choices=[(-1, "Dislike"), (0, "Neutral"), (1, "Like")])
    timestamp = models.DateTimeField(auto_now=True)
    class Meta:
        unique_together = ('user', 'product')  # Ensures one preference per product per user

    def __str__(self):
        return f"{self.user.username} - {self.product.name}: {self.preference}"