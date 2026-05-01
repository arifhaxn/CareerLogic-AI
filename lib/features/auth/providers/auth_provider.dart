import 'package:flutter/material.dart';
import '../models/user_model.dart'; // 1. Added the import for your new model
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  UserModel? _currentUser;
  String? _errorMessage;

  // Getters for the UI to consume
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _currentUser != null; // 2. Updated to check the model, not the token
  UserModel? get currentUser =>
      _currentUser; // 3. Added getter so your UI can access the user's data
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final token = await _authService.login(email, password);
      if (token != null) {
        // 4. Construct a mock UserModel with the returned token
        _currentUser = UserModel(
          id: 'mock_id_123',
          name:
              'CareerLogic User', // Placeholder name until the backend returns real data
          email: email,
          token: token,
        );
        // TODO: Later, we will save this token to shared_preferences for offline caching[cite: 1]
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final token = await _authService.register(name, email, password);
      if (token != null) {
        // 5. Construct a mock UserModel for the new user
        _currentUser = UserModel(
          id: 'mock_id_123',
          name: name,
          email: email,
          token: token,
        );
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void logout() async {
    _setLoading(true);
    await _authService.logout();
    _currentUser = null; // 6. Clear the user model on logout
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
