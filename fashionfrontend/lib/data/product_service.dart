import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Axent/models/card_queue_model.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  static final Dio _dio = Dio();
  static const String _baseUrl = 'https://axentbackend.onrender.com';

  // Fetch full product details by ID from Django backend
  static Future<CardData?> getProductById(String productId) async {
    try {
      
      
      final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();
      
      final response = await _dio.get(
        '$_baseUrl/preferences/product_detail/$productId/',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          validateStatus: (status) => status! < 500,
        ),
      );


      if (response.statusCode == 200) {
        final data = response.data;
        
        // Map Django backend data to CardData model
        return CardData(
          id: data['id']?.toString() ?? '',
          title: data['title'] ?? '',
          brand: data['brand'] ?? '',
          description: data['description'] ?? '',
          upcoming: data['upcoming'] ?? false,
          colorway: List<String>.from(data['colorway'] ?? []),
          trait: data['trait'] ?? false,
          retailPrice: double.parse((data['retailprice'] ?? 0)),
          sizeLowestAsks: Map<String, double>.from(data['size_lowest_asks'] ?? {}),
          images: data['images'] != null 
              ? List<String>.from(data['images'].map((img) => img['image_url'] ?? ''))
              : [],
          likedAt: DateTime.now(),
          images360: data['images360'] != null 
              ? List<String>.from(data['images360'].map((img) => img['image_url'] ?? ''))
              : [],
          model: data['model'],
          category: data['category'],
          secondaryCategory: data['secondary_category'],
          sku: data['sku'],
          releaseDate: data['release_date'] != null 
              ? DateTime.parse(data['release_date']) 
              : null,
          link: data['link'],
          lowestAsk: data['lowest_ask']?.toDouble(),
          updatedAt: data['updated_at'] != null 
              ? DateTime.parse(data['updated_at']) 
              : null,
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
} 