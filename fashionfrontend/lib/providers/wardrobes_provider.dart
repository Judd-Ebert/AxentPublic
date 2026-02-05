import 'package:flutter/foundation.dart';
import 'package:Axent/models/wardrobe_model.dart';
import 'package:Axent/data/wardrobes_service.dart';

class WardrobesProvider extends ChangeNotifier {
  List<Wardrobe> _wardrobes = [];
  bool _isLoading = false;
  String? _error;

  List<Wardrobe> get wardrobes => _wardrobes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize the provider
  Future<void> initialize() async {
    await refreshWardrobes();
  }

  // Refresh wardrobes from the API
  Future<void> refreshWardrobes() async {
    try {
      _setLoading(true);
      _error = null;
      
      final wardrobes = await WardrobesService.fetchWardrobes();
      
      _wardrobes = wardrobes;
      
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Create a new wardrobe
  Future<bool> createWardrobe(String name) async {
    try {
      _setLoading(true);
      _error = null;
      
      final response = await WardrobesService.createWardrobe(name);
      
      // Add to local state instead of refreshing from server
      final newWardrobe = Wardrobe(
        id: response['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        productIds: [],
        createdAt: DateTime.now(),
      );
      _wardrobes.add(newWardrobe);
      notifyListeners();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Delete a wardrobe
  Future<bool> deleteWardrobe(String wardrobeId) async {
    try {
      _setLoading(true);
      _error = null;
      
      await WardrobesService.deleteWardrobe(wardrobeId);
      
      // Remove from local state
      _wardrobes.removeWhere((wardrobe) => wardrobe.id == wardrobeId);
      notifyListeners();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Add a product to a wardrobe
  Future<bool> addToWardrobe(String wardrobeId, String productId) async {
    try {
      await WardrobesService.addToWardrobe(wardrobeId, productId);
      
      // Update local state
      final wardrobeIndex = _wardrobes.indexWhere((w) => w.id == wardrobeId);
      if (wardrobeIndex != -1) {
        final wardrobe = _wardrobes[wardrobeIndex];
        final updatedProductIds = List<String>.from(wardrobe.productIds);
        if (!updatedProductIds.contains(productId)) {
          updatedProductIds.add(productId);
          _wardrobes[wardrobeIndex] = Wardrobe(
            id: wardrobe.id,
            name: wardrobe.name,
            productIds: updatedProductIds,
            createdAt: wardrobe.createdAt,
            coverImageUrl: wardrobe.coverImageUrl,
          );
          notifyListeners();
        }
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove a product from a wardrobe
  Future<bool> removeFromWardrobe(String wardrobeId, String productId) async {
    try {
      await WardrobesService.removeFromWardrobe(wardrobeId, productId);
      
      // Update local state
      final wardrobeIndex = _wardrobes.indexWhere((w) => w.id == wardrobeId);
      if (wardrobeIndex != -1) {
        final wardrobe = _wardrobes[wardrobeIndex];
        final updatedProductIds = List<String>.from(wardrobe.productIds);
        updatedProductIds.remove(productId);
        _wardrobes[wardrobeIndex] = Wardrobe(
          id: wardrobe.id,
          name: wardrobe.name,
          productIds: updatedProductIds,
          createdAt: wardrobe.createdAt,
          coverImageUrl: wardrobe.coverImageUrl,
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get a specific wardrobe by ID
  Wardrobe? getWardrobeById(String wardrobeId) {
    try {
      return _wardrobes.firstWhere((wardrobe) => wardrobe.id == wardrobeId);
    } catch (e) {
      return null;
    }
  }

  // Get wardrobes containing a specific product
  List<Wardrobe> getWardrobesContainingProduct(String productId) {
    return _wardrobes.where((wardrobe) {
      return wardrobe.productIds.contains(productId);
    }).toList();
  }

  // Check if a product is in any wardrobe
  bool isProductInAnyWardrobe(String productId) {
    return _wardrobes.any((wardrobe) {
      return wardrobe.productIds.contains(productId);
    });
  }

  // Get total number of products across all wardrobes
  int get totalProducts {
    final allProductIds = <String>{};
    for (final wardrobe in _wardrobes) {
        allProductIds.addAll(wardrobe.productIds);
    }
    return allProductIds.length;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh cache for a specific wardrobe
  void refreshWardrobeCache(String wardrobeId) {
    WardrobesService.clearWardrobeCache(wardrobeId);
  }

  // Clear all cache
  void clearAllCache() {
    WardrobesService.clearAllCache();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
} 