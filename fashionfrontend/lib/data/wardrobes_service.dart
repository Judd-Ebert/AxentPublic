import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Axent/models/wardrobe_model.dart';
import 'package:Axent/models/card_queue_model.dart';

class WardrobesService {
  static final WardrobesService _instance = WardrobesService._internal();
  factory WardrobesService() => _instance;
  WardrobesService._internal();

  static final Dio _dio = Dio();
  static const String _baseUrl = 'https://axentbackend.onrender.com/wardrobes';
  
  // Simple cache for wardrobe products
  static final Map<String, List<CardData>> _productCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  static Future<String> _getIdToken() async {
    return (await FirebaseAuth.instance.currentUser!.getIdToken())!;
  }

  static Future<String> _getUserId() async {
    final decodedToken = await FirebaseAuth.instance.currentUser!.getIdTokenResult();
    final userId = decodedToken.claims?['user_id'];
    if (userId == null) {
      throw Exception('User ID not found in token');
    }
    return userId;
  }

  // Fetch all wardrobes for the current user
  static Future<List<Wardrobe>> fetchWardrobes() async {
    try {
      final idToken = await _getIdToken();
      final userId = await _getUserId();
      
      final response = await _dio.get(
        '$_baseUrl/user/',
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
        queryParameters: {'firebase_uid': userId},
      );


      if (response.data == null) return [];
      
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Wardrobe.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Create a new wardrobe
  static Future<Map<String, dynamic>> createWardrobe(String name) async {
    try {
      final idToken = await _getIdToken();
      final userId = await _getUserId();
      
      final response = await _dio.post(
        '$_baseUrl/',
        data: {'name': name, 'user': userId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Delete a wardrobe
  static Future<void> deleteWardrobe(String wardrobeId) async {
    try {
      final idToken = await _getIdToken();
      await _dio.delete(
        '$_baseUrl/$wardrobeId/',
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Clear cache for a specific wardrobe
  static void clearWardrobeCache(String wardrobeId) {
    _productCache.remove(wardrobeId);
    _cacheTimestamps.remove(wardrobeId);
  }

  // Clear all cache
  static void clearAllCache() {
    _productCache.clear();
    _cacheTimestamps.clear();
  }

  // Add a product to a wardrobe
  static Future<void> addToWardrobe(String wardrobeId, String productId) async {
    try {
      final idToken = await _getIdToken();
      
      final response = await _dio.post(
        '$_baseUrl/$wardrobeId/add_item/',
        data: {'product_id': productId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          followRedirects: true,
          validateStatus: (status) => status! < 600, // Allow 500 errors to be handled
        ),
      );
      
      
      if (response.statusCode! >= 400) {
        throw Exception('Server error: ${response.statusCode} - ${response.data}');
      }
      
      // Clear cache for this wardrobe
      clearWardrobeCache(wardrobeId);
    } catch (e) {
      rethrow;
    }
  }

  // Remove a product from a wardrobe
  static Future<void> removeFromWardrobe(String wardrobeId, String productId) async {
    try {
      final idToken = await _getIdToken();
      await _dio.post(
        '$_baseUrl/$wardrobeId/remove_item/',
        data: {'product_id': productId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      // Clear cache for this wardrobe
      clearWardrobeCache(wardrobeId);
    } catch (e) {
      rethrow;
    }
  }

  // Get products in a wardrobe
  static Future<List<CardData>> getWardrobeProducts(String wardrobeId) async {
    try {
      // Check cache first
      final now = DateTime.now();
      final cacheTime = _cacheTimestamps[wardrobeId];
      if (cacheTime != null && now.difference(cacheTime) < _cacheExpiry) {
        final cachedProducts = _productCache[wardrobeId];
        if (cachedProducts != null) {
          return cachedProducts;
        }
      }
      
      final idToken = await _getIdToken();
      
      
      // Fetch wardrobe details
      final wardrobeResponse = await _dio.get(
        '$_baseUrl/$wardrobeId/',
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      // Extract products directly from the items array in the wardrobe response
      final items = wardrobeResponse.data['items'] as List<dynamic>? ?? [];
      final products = <CardData>[];
      
      for (final item in items) {
        try {
          final productData = item['product'] as Map<String, dynamic>;
          final cardData = CardData.fromJson(productData);
          products.add(cardData);
        } catch (e) {
          // Skip invalid product data
          continue;
        }
      }

      // Cache the results
      _productCache[wardrobeId] = products;
      _cacheTimestamps[wardrobeId] = now;

      return products;
    } catch (e) {
      return [];
    }
  }

  // Check if a product is in a wardrobe
  static Future<bool> isProductInWardrobe(String wardrobeId, String productId) async {
    try {
      final products = await getWardrobeProducts(wardrobeId);
      return products.any((product) => product.id == productId);
    } catch (e) {
      return false;
    }
  }

  // Get all wardrobes containing a specific product (optimized)
  static Future<List<Wardrobe>> getWardrobesContainingProduct(String productId, {List<Wardrobe>? localWardrobes}) async {
    try {
      // If we have local wardrobe data with product IDs, use that first
      if (localWardrobes != null) {
        final containingWardrobes = localWardrobes.where((wardrobe) {
          return wardrobe.productIds.contains(productId);
        }).toList();
        
        // If we found wardrobes locally, return them
        if (containingWardrobes.isNotEmpty) {
          return containingWardrobes;
        }
      }
      
      // Fallback to API calls only if needed
      final allWardrobes = await fetchWardrobes();
      final containingWardrobes = <Wardrobe>[];
      
      for (final wardrobe in allWardrobes) {
        final isContaining = await isProductInWardrobe(wardrobe.id, productId);
        if (isContaining) {
          containingWardrobes.add(wardrobe);
        }
      }
      
      return containingWardrobes;
    } catch (e) {
      return [];
    }
  }
} 