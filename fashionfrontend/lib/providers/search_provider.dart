import 'package:dio/dio.dart';
import 'package:Axent/models/card_queue_model.dart';
import 'package:flutter/material.dart';


class SearchProvider with ChangeNotifier {
  String _searchQuery = '';
  List<CardData> _searchResults = [];
  bool _isLoading = false;
  final apiBaseUrl = 'https://axentbackend.onrender.com';

  // Store previous search queries
  final List<String> _previousSearches = [];

  String get searchQuery => _searchQuery;
  List<CardData> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  List<String> get previousSearches => List.unmodifiable(_previousSearches);

  void setSearchQuery(String query) {
    _searchQuery = query;
    _searchCatalog();
    notifyListeners();
  }

  void addPreviousSearch(String query) {
    if (query.isNotEmpty && !_previousSearches.contains(query)) {
      _previousSearches.insert(0, query); // Most recent first
      if (_previousSearches.length > 10) {
        _previousSearches.removeLast();
      }
      notifyListeners();
    }
  }

  void _searchCatalog() async {
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await Dio().get('$apiBaseUrl/products/search/?query=$_searchQuery');
      final List<dynamic> data = response.data;
      _searchResults = data.map((json) => CardData.fromJson(json)).toList();
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  void clearPreviousSearches() {
    _previousSearches.clear();
    notifyListeners();
  }

  void removePreviousSearch(String query) {
    _previousSearches.remove(query);
    notifyListeners();
  }
}