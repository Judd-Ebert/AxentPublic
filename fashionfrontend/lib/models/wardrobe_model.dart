

class Wardrobe {
  final String id;
  final String name;
  final List<String> productIds;
  final DateTime createdAt;
  final String? coverImageUrl;

  Wardrobe({
    required this.id,
    required this.name,
    this.productIds = const [],
    required this.createdAt,
    this.coverImageUrl,
  });

  factory Wardrobe.fromJson(Map<String, dynamic> json) {
    return Wardrobe(
      id: json['id'].toString(),
      name: json['name'],
      productIds: json['product_ids'] != null ? List<String>.from(json['product_ids']) : [],
      createdAt: DateTime.parse(json['created_at']),
      coverImageUrl: json['cover_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'product_ids': productIds,
      'created_at': createdAt.toIso8601String(),
      'cover_image_url': coverImageUrl,
    };
  }
}