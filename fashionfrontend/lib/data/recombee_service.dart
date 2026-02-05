import 'package:dio/dio.dart';
import 'package:Axent/models/card_queue_model.dart';
import 'package:Axent/config/recombee_config.dart';

class RecombeeService {
  static final RecombeeService _instance = RecombeeService._internal();
  factory RecombeeService() => _instance;
  RecombeeService._internal();

  static final Dio _dio = Dio();
  static final RESULTCOUNT = 10;
  static final String publicToken = 'rRwGfBTEEFjAAsdQJgNE7DeZ0MofM1hfBwbS7B5xD6bA3VTxXptecN71Cxro8nw2';

  // Search products using Recombee
  static Future<List<CardData>> searchProducts(String query, {
    int count = 10,
    required String userId,
    Map<String, dynamic>? filters,
  }) async {
    try {

      final response = await _dio.get(
        buildRecombeeUrl(query, userId, RESULTCOUNT),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      
      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['recomms'] ?? [];
        return results.map<CardData>((item) {
          final properties = item['values'] ?? {};
          return CardData(
            id: item['id'] ?? '',
            title: properties['title'] ?? '',
            brand: properties['brand'] ?? '',
            description: '',
            upcoming: false,
            colorway: [],
            trait: false,
            retailPrice: (properties['retailprice'] ?? 0).toDouble(),
            sizeLowestAsks: {},
            images: properties['image'] != null ? [properties['image']] : ['assets/images/Shoes1.jpg'],
            likedAt: DateTime.now(),
            images360: ['assets/images/Shoes1.jpg'],
          );
        }).toList();
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }
} 