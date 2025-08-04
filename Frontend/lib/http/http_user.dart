import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/model_user.dart';
import '../auth_service.dart';

class UserApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      headers: {'Content-Type': 'application/json'},
      connectTimeout: Duration(seconds: 20),
      receiveTimeout: Duration(seconds: 20),
    ),
  );

  static void init() {
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          print("DIO ERROR: ${e.message}");
          return handler.next(e);
        },
      ),
    );
  }

  // POST Register
  static Future<bool> registerUser(UserModelRegister user) async {
    try {
      final response = await _dio.post('/user/register', data: user.toJson());
      return response.statusCode == 200;
    } catch (e) {
      print("Register Error: $e");
      return false;
    }
  }

  // POST Login
  static Future<bool> loginUser(UserModelLogin user) async {
    try {
      final response = await _dio.post('/user/login', data: user.toJson());
      if (response.statusCode == 200) {
        final token = response.data['token'];
        await AuthService.setToken(token);
        return true;
      }
    } catch (e) {
      print("Login Error: $e");
    }
    return false;
  }

  // GET
  static Future<Response?> getProtectedData() async {
    try {
      final response = await _dio.get('/protected-endpoint');
      return response;
    } catch (e) {
      print("Protected Data Error: $e");
      return null;
    }
  }
}
