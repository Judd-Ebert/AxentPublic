from django.urls import path
from . import views

urlpatterns = [
    path('', views.WardrobeViewSet.as_view({'post': 'create'}), name='wardrobe-create'),
    path('user/', views.WardrobeViewSet.as_view({'get': 'list_by_user'}), name='wardrobe-list-by-user'),
    path('<uuid:pk>/', views.WardrobeViewSet.as_view({
        'get': 'retrieve',
        'put': 'update',
        'patch': 'partial_update',
        'delete': 'destroy'
    }), name='wardrobe-detail'),
    path('<uuid:pk>/add_item/', views.WardrobeViewSet.as_view({'post': 'add_item'}), name='wardrobe-add-item'),
    path('<uuid:pk>/remove_item/', views.WardrobeViewSet.as_view({'post': 'remove_item'}), name='wardrobe-remove-item'),
]