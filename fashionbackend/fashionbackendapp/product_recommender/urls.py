from django.urls import path
from . import views

urlpatterns = [
    path('recommend/', views.ProductViewSet.as_view({'get': 'recommend'}), name='product-recommend'),
    path('search/', views.ProductViewSet.as_view({'get': 'search'}), name='product-search'),
]