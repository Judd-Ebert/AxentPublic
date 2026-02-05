import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:Axent/models/card_queue_model.dart';

class LikedProductsService extends ChangeNotifier {
  static final LikedProductsService _instance = LikedProductsService._internal();
  factory LikedProductsService() => _instance;
  LikedProductsService._internal();

  final List<dynamic> _likedProducts = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);
  Future<List<dynamic>> Function()? _apiFetchFunction;

  List<dynamic> get likedProducts => List.unmodifiable(_likedProducts);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Get recent products (most recent 15)
  List<dynamic> get recentProducts {
    final recent = _likedProducts.take(15).toList();
    return recent.reversed.toList(); // Show newest first
  }

  // Check if cache is still valid
  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized && _isCacheValid) return;
    
    await refreshLikedProducts();
    _isInitialized = true;
  }

  // Refresh liked products from API
  Future<void> refreshLikedProducts() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final products = await _fetchLikedProductsFromAPI();
      _likedProducts.clear();
      _likedProducts.addAll(products);
      _lastFetchTime = DateTime.now();
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a product to liked products (optimistic update)
  void addLikedProduct(dynamic product) {
    // Check if product already exists
    final existingIndex = _likedProducts.indexWhere(
      (p) => p['id'] == product['id']
    );
    
    if (existingIndex == -1) {
      _likedProducts.insert(0, product); // Add to beginning (most recent)
      notifyListeners();
    }
  }

  // Add a CardData product to liked products (convenience method)
  void addLikedProductFromCardData(CardData card) {
    final productMap = {
      'id': card.id,
      'title': card.title,
      'brand': card.brand,
      'model': card.model,
      'images': card.images,
      'images360': card.images360,
      'lowest_ask': card.lowestAsk,
      'retail_price': card.retailPrice,
      'category': card.category,
      'secondary_category': card.secondaryCategory,
      'sku': card.sku,
      'colorway': card.colorway,
      'release_date': card.releaseDate?.toIso8601String(),
      'upcoming': card.upcoming,
      'trait': card.trait,
      'link': card.link,
      'updated_at': card.updatedAt?.toIso8601String(),
      'size_lowest_asks': card.sizeLowestAsks,
    };
    addLikedProduct(productMap);
  }

  // Remove a product from liked products (optimistic update)
  void removeLikedProduct(String productId) {
    final index = _likedProducts.indexWhere(
      (p) => p['id'] == productId
    );
    
    if (index != -1) {
      _likedProducts.removeAt(index);
      notifyListeners();
    }
  }

  // Get a specific product by ID
  dynamic getProductById(String productId) {
    try {
      return _likedProducts.firstWhere((p) => p['id'] == productId);
    } catch (e) {
      return null;
    }
  }

  // Check if a product is liked
  bool isProductLiked(String productId) {
    return _likedProducts.any((p) => p['id'] == productId);
  }

  // Get products by brand
  List<dynamic> getProductsByBrand(String brand) {
    return _likedProducts.where((p) => p['brand'] == brand).toList();
  }

  // Search products
  List<dynamic> searchProducts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _likedProducts.where((product) {
      final title = product['title']?.toString().toLowerCase() ?? '';
      final brand = product['brand']?.toString().toLowerCase() ?? '';
      final model = product['model']?.toString().toLowerCase() ?? '';
      
      return title.contains(lowercaseQuery) ||
             brand.contains(lowercaseQuery) ||
             model.contains(lowercaseQuery);
    }).toList();
  }

  // Clear all data (for logout)
  void clear() {
    _likedProducts.clear();
    _isInitialized = false;
    _lastFetchTime = null;
    _isLoading = false;
    notifyListeners();
  }

  // Method to set the API fetch function (called from the heart page service)
  static void setAPIFetchFunction(Future<List<dynamic>> Function() fetchFunction) {
    _instance._apiFetchFunction = fetchFunction;
  }

  // Private method to fetch from API
  Future<List<dynamic>> _fetchLikedProductsFromAPI() async {
    if (_apiFetchFunction != null) {
      return await _apiFetchFunction!();
    }
    throw UnimplementedError('API fetch function not set');
  }
} 