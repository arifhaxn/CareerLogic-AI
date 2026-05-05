import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  UserModel? _currentUser;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  // --- NEW: Check for saved session on startup ---
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      _currentUser = UserModel(
        id: prefs.getString('user_id') ?? '',
        name: prefs.getString('user_name') ?? 'User',
        email: prefs.getString('user_email') ?? '',
        token: token,
      );
      notifyListeners();
    }
  }

  // --- NEW: Helper method to save session ---
  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', user.token);
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
  }

  // --- NEW: Helper method to clear session ---
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final responseData = await _authService.login(email, password);

      if (responseData != null && responseData['token'] != null) {
        _currentUser = UserModel(
          id: responseData['user']?['_id'] ?? '',
          name: responseData['user']?['name'] ?? 'User',
          email: responseData['user']?['email'] ?? email,
          token: responseData['token'],
        );
        await _saveSession(_currentUser!); // Save to device!
        return true;
      } else {
        _errorMessage = 'Login succeeded, but the token was missing.';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final responseData = await _authService.register(name, email, password);

      if (responseData != null && responseData['token'] != null) {
        _currentUser = UserModel(
          id: responseData['user']?['_id'] ?? '',
          name: responseData['user']?['name'] ?? name,
          email: responseData['user']?['email'] ?? email,
          token: responseData['token'],
        );
        await _saveSession(_currentUser!); // Save to device!
        return true;
      } else {
        _errorMessage = 'Registration succeeded, but the token was missing.';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void logout() async {
    _setLoading(true);
    await _authService.logout();
    _currentUser = null;
    await _clearSession(); // Delete from device!
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