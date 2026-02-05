import 'package:flutter/material.dart';
import 'package:Axent/data/liked_products_service.dart';
import 'package:Axent/models/card_queue_model.dart';

class LikedProductsProvider extends ChangeNotifier {
  final LikedProductsService _service = LikedProductsService();

  LikedProductsService get service => _service;

  // Expose service methods for easy access
  List<dynamic> get likedProducts => _service.likedProducts;
  bool get isLoading => _service.isLoading;
  bool get isInitialized => _service.isInitialized;

  // Initialize the service
  Future<void> initialize() async {
    await _service.initialize();
    notifyListeners();
  }

  // Refresh liked products
  Future<void> refreshLikedProducts() async {
    await _service.refreshLikedProducts();
    notifyListeners();
  }

  // Add a product to liked products
  void addLikedProduct(dynamic product) {
    _service.addLikedProduct(product);
    notifyListeners();
  }

  // Add a CardData product to liked products (convenience method)
  void addLikedProductFromCardData(CardData card) {
    _service.addLikedProductFromCardData(card);
    notifyListeners();
  }

  // Remove a product from liked products
  void removeLikedProduct(String productId) {
    _service.removeLikedProduct(productId);
    notifyListeners();
  }

  // Check if a product is liked
  bool isProductLiked(String productId) {
    return _service.isProductLiked(productId);
  }

  // Clear all data
  void clear() {
    _service.clear();
    notifyListeners();
  }
} 