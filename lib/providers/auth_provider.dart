import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _loading = true;

  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _onUserLoaded() {
    // This will trigger PostProvider to fetch posts
    notifyListeners();
  }

  Future<void> _initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    
    if (userJson != null) {
      _user = jsonDecode(userJson);
      _loading = false;
      notifyListeners();

      // Verify session with server
      try {
        final result = await ApiService.get(
          'get_user_profile?profile_id=${_user!['id']}&current_user_id=${_user!['id']}'
        );
        
        if (result['success']) {
          _user = result['data']['user'];
          await prefs.setString('user', jsonEncode(_user));
          // Trigger post loading after user is verified
          _onUserLoaded();
        } else {
          // User was deleted or session expired
          await logout();
        }
      } catch (e) {
        // Keep local profile if network error
        print('Network error during session verification: $e');
        _onUserLoaded();
      }
    } else {
      _loading = false;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String emailOrUsername, String password) async {
    _loading = true;
    notifyListeners();

    try {
      final result = await ApiService.post('login', {
        'login_id': emailOrUsername,
        'password': password,
      });

      if (result['success']) {
        _user = result['data'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user));
        return {'success': true, 'user': _user};
      } else {
        return {'success': false, 'error': result['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'حدث خطأ غير متوقع'};
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    File? profileImage,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      String? photoUrl;
      if (profileImage != null) {
        final uploadResult = await ApiService.upload('upload_media', profileImage);
        if (uploadResult['success']) {
          photoUrl = uploadResult['data']['url'];
        }
      }

      final username = email.split('@')[0];

      final result = await ApiService.post('register', {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
        'photo': photoUrl,
      });

      if (result['success']) {
        _user = result['data'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user));
        return {'success': true, 'user': _user};
      } else {
        return {'success': false, 'error': result['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'حدث خطأ أثناء الاتصال بالخادم'};
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    if (_user == null) return {'success': false, 'error': 'يجب تسجيل الدخول أولاً'};

    try {
      final result = await ApiService.post('update_profile', {
        'user_id': _user!['id'],
        ...profileData,
      });

      if (result['success']) {
        _user = result['data'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user));
        notifyListeners();
        return {'success': true, 'user': _user};
      } else {
        return {'success': false, 'error': result['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'حدث خطأ أثناء الاتصال بالخادم'};
    }
  }
}
