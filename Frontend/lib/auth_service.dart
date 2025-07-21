import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _tokenKey = 'jwt_token';

  /// Simpan token ke SharedPreferences
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Ambil token dari SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Hapus token (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Cek apakah token tersedia
  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  /// Ambil token dalam format Bearer (untuk header Authorization)
  static Future<String?> getBearerToken() async {
    final token = await getToken();
    return token != null ? 'Bearer $token' : null;
  }

  /// Simpan token dari respons login (misalnya response['access_token'])
  static Future<void> setTokenFromResponse(
    Map<String, dynamic> response,
  ) async {
    final token = response['access_token'] ?? response['token'];
    if (token != null && token is String) {
      await setToken(token);
    }
  }
}
