import 'dart:collection';
import 'package:flutter/material.dart';

class CardData {
  final String id;
  final String title;
  final String brand;
  final String? model;
  final String? description;
  final String? sku;
  final String? slug;
  final String? category;
  final String? secondaryCategory;
  final bool upcoming;
  final DateTime? updatedAt;
  final String? link;
  final List<String> colorway;
  final bool trait;
  final DateTime? releaseDate;
  final double retailPrice;
  final double? lowestAsk;
  final Map<String, double> sizeLowestAsks;
  final List<String> images;
  final List<String> images360;
  final DateTime likedAt;
  final String? recommID;

  CardData(
      {required this.id,
      required this.title,
      required this.brand,
      this.model,
      this.description,
      this.sku,
      this.slug,
      this.category,
      this.secondaryCategory,
      required this.upcoming,
      this.updatedAt,
      this.link,
      required this.colorway,
      required this.trait,
      this.releaseDate,
      required this.retailPrice,
      this.lowestAsk,
      required this.sizeLowestAsks,
      required this.images,
      required this.likedAt,
      required this.images360,
      this.recommID});

  factory CardData.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      try {
        return double.parse(value.toString().replaceAll(',', ''));
      } catch (e) {
        return 0.0;
      }
    }

    // Try to get lowest ask from direct field first, then from variants, then from size_lowest_asks
    double? lowestAskValue;
    if (json['lowest_ask'] != null) {
      lowestAskValue = parsePrice(json['lowest_ask']);
    } else if (json['variants'] is List &&
        (json['variants'] as List).isNotEmpty) {
      // Try to get lowest ask from variants
      List<dynamic> variants = json['variants'] as List;
      List<double> lowestAsks = [];
      for (var variant in variants) {
        if (variant['lowest_ask'] != null) {
          double ask = parsePrice(variant['lowest_ask']);
          if (ask > 0) {
            lowestAsks.add(ask);
          }
        }
      }
      if (lowestAsks.isNotEmpty) {
        lowestAsks.sort();
        lowestAskValue = lowestAsks.first;
      }
    } else if (json['size_lowest_asks'] is Map) {
      // Try to get lowest ask from size_lowest_asks
      Map<String, dynamic> sizeAsks =
          json['size_lowest_asks'] as Map<String, dynamic>;
      List<double> lowestAsks = [];
      for (var ask in sizeAsks.values) {
        if (ask != null) {
          double askValue = parsePrice(ask);
          if (askValue > 0) {
            lowestAsks.add(askValue);
          }
        }
      }
      if (lowestAsks.isNotEmpty) {
        lowestAsks.sort();
        lowestAskValue = lowestAsks.first;
      }
    }

    return CardData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'],
      description: json['description'],
      sku: json['sku'],
      slug: json['slug'],
      category: json['category'],
      secondaryCategory: json['secondary_category'],
      upcoming: json['upcoming'] ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      link: json['link'],
      colorway:
          json['colorway'] is List ? List<String>.from(json['colorway']) : [],
      trait: json['trait'] ?? false,
      releaseDate: json['release_date'] != null
          ? DateTime.tryParse(json['release_date'])
          : null,
      retailPrice: parsePrice(json['retailprice']),
      lowestAsk: lowestAskValue,
      sizeLowestAsks: () {
        // Debug logging for size_lowest_asks

        if (json['size_lowest_asks'] is Map) {
          Map<String, dynamic> sizeAsks =
              json['size_lowest_asks'] as Map<String, dynamic>;

          Map<String, double> result = Map<String, double>.from(sizeAsks);
          return result;
        } else {
          return <String, double>{};
        }
      }(),
      images: json['images'] is List
          ? (json['images'] as List)
              .map((e) {
                if (e is String) {
                  return e;
                } else if (e is Map && e['image_url'] != null) {
                  return e['image_url'].toString();
                } else {
                  return 'assets/images/Shoes1.jpg';
                }
              })
              .toList()
          : ['assets/images/Shoes1.jpg'],
      likedAt: DateTime.now(),
      images360: () {
        if (json['images360'] == null) {
          return ['assets/images/Shoes1.jpg'];
        }

        if (json['images360'] is List) {
          List<dynamic> images360List = json['images360'] as List;

          if (images360List.isEmpty) {
            return ['assets/images/Shoes1.jpg'];
          }

          // Try different possible structures
          List<String> result = [];
          for (var item in images360List) {
            if (item is String) {
              result.add(item);
            } else if (item is Map) {
              // Try different possible key names
              String? url = item['image360_url'] ??
                  item['image_url'] ??
                  item['url'] ??
                  item['src'];
              if (url != null) {
                result.add(url.toString());
              }
            }
          }

          return result.isNotEmpty ? result : ['assets/images/Shoes1.jpg'];
        }

        return ['assets/images/Shoes1.jpg'];
      }(),
      recommID: json['recommID'],
    );
  }

  String get formattedPrice => '\$${retailPrice.toStringAsFixed(2)}';
}

class CardQueueModel with ChangeNotifier {
  final Queue<CardData> _queue = Queue<CardData>();
  bool _isFetchingCards = false;

  Queue<CardData> get queue => _queue;
  
  bool get isFetchingCards => _isFetchingCards;

  void setFetchingCards(bool isFetching) {
    _isFetchingCards = isFetching;
    notifyListeners();
  }

  void addCardFirst(CardData data) {
    _queue.addFirst(data);
  }

  void addCard(CardData data) {
    _queue.addLast(data);
    notifyListeners();
  }

  void removeFirstCard() {
    if (_queue.isNotEmpty) {
      _queue.removeFirst();
      notifyListeners();
    }
  }

  void removeLastCard() {
    // ignore: unnecessary_null_comparison
    if (_queue.last != null) {
      _queue.removeLast();
      notifyListeners();
    }
  }

  String getCurrentCardId() {
    if (_queue.isEmpty) {
      return "";
    }
    return _queue.first.recommID ?? "";
  }

  String getLastCardId() {
    try {
      if (_queue.isEmpty) {
        return "";
      }
      
      final lastCard = _queue.last;
      if (lastCard.recommID != null && lastCard.recommID!.isNotEmpty) {
        return lastCard.recommID!;
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }

  // Clear or reset the queue
  void resetQueue() {
    _queue.clear();
    notifyListeners();
  }

  int get queueLength {
    return _queue.length;
  }

  CardData? get firstCard {
    return _queue.isNotEmpty ? _queue.first : null;
  }

  CardData? get secondCard {
    return _queue.length > 1 ? _queue.elementAt(1) : null;
  }

  CardData? get thirdCard {
    return _queue.length > 2 ? _queue.elementAt(2) : null;
  }

  bool get isEmpty {
    return _queue.isEmpty;
  }

  bool get isNotEmpty {
    return _queue.isNotEmpty;
  }
}

class PreviousProductModel with ChangeNotifier {
  final List<Map<String, dynamic>> _previousShoes = [];

  List<Map<String, dynamic>> get previousShoes => _previousShoes;

  void addSwipe(CardData data, int direction) {
    _previousShoes.add({
      'data': data,
      'direction': direction, // 1 for right swipe, -1 for left swipe
    });
    notifyListeners();
  }

  Map<String, dynamic>? getLastSwipe() {
    if (_previousShoes.isEmpty) return null;
    return _previousShoes.last;
  }

  void removeLastSwipe() {
    if (_previousShoes.isNotEmpty) {
      _previousShoes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    _previousShoes.clear();
    notifyListeners();
  }
}
