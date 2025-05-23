import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/models/user.dart';
import '../utils/api_config.dart';

class UserService {
  static const String _userKey = 'user_data';
 
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    
    return null;
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  static Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null;
  }

  static Future<String?> getToken() async {
    final user = await getUser();
    return user?.token;
  }

  static Future<void> updateUserInfo(Map<String, dynamic> userData) async {
    final user = await getUser();
    if (user != null) {
      
      final Map<String, dynamic> currentUserData = user.toJson();

      currentUserData.addAll(userData);
 
      if (userData.containsKey('profilePicture')) {
        currentUserData['profilePicture'] = userData['profilePicture'];
      }

      final updatedUser = User.fromJson(currentUserData);

      await saveUser(updatedUser);
    }
  }

}







