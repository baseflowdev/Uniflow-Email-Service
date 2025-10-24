import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _error;

  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

