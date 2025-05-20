import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/models/user.dart';
import '../utils/api_config.dart';

class UserService {
  static const String _userKey = 'user_data';
  
  // Save user data to shared preferences
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
  
  // Get user data from shared preferences
  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    
    return null;
  }
  
  // Clear user data from shared preferences (logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null;
  }
  
  // Get auth token
  static Future<String?> getToken() async {
    final user = await getUser();
    return user?.token;
  }

  // Add this method to update user info
  static Future<void> updateUserInfo(Map<String, dynamic> userData) async {
    final user = await getUser();
    if (user != null) {
      // Update user properties with new data
      final updatedUser = User.fromJson({...userData, 'token': user.token});
      // Save the updated user
      await saveUser(updatedUser);
    }
  }

}






