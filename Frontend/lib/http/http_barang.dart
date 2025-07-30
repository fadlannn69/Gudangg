import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gudkoptell/auth_service.dart';
import 'package:gudkoptell/model/model_barang.dart';

class BarangApiService {
  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: dotenv.env['API_BASE_URL'] ?? '',
            headers: {'Content-Type': 'application/json'},
            connectTimeout: Duration(seconds: 20),
            receiveTimeout: Duration(seconds: 20),
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await AuthService.getToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              return handler.next(options);
            },
            onError: (e, handler) {
              if (e.response?.statusCode == 401) {
                print("Token expired atau tidak valid");
                // TODO: Handle logout/refresh token/redirect
              }
              print("DIO ERROR: ${e.response?.statusCode} - ${e.message}");
              return handler.next(e);
            },
          ),
        )
        ..interceptors.add(
          LogInterceptor(
            request: true,
            requestBody: true,
            responseBody: true,
            responseHeader: false,
            error: true,
            logPrint: (obj) {
              if (kDebugMode) print(obj);
            },
          ),
        );

  // GET
  static Future<List<ModelBarang>> fetchBarang({
    int skip = 0,
    int limit = 10,
    String? jenis,
  }) async {
    try {
      final response = await _dio.get(
        '/barang/ambil',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (jenis != null) 'jenis': jenis,
        },
      );
      final data = response.data as List;
      return data.map((json) => ModelBarang.fromJson(json)).toList();
    } catch (e) {
      print("Error fetchBarang: $e");
      return [];
    }
  }

  // POST JSON (Tanpa Gambar)
  static Future<bool> tambahBarang(ModelBarang barang) async {
    try {
      final response = await _dio.post('/barang/tambah', data: barang.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error tambahBarang: $e");
      return false;
    }
  }

  // POST FormData (Dengan Gambar)
  static Future<bool> tambahBarangWithFormData(FormData formData) async {
    try {
      final response = await _dio.post('/barang/tambah', data: formData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error tambahBarangWithFormData: $e");
      return false;
    }
  }

  // PUT
  static Future<bool> updateBarang(String nama, BarangUpdate barang) async {
    try {
      final response = await _dio.put(
        '/barang/update/$nama',
        data: barang.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updateBarang: $e");
      return false;
    }
  }

  // DELETE
  static Future<bool> deleteBarang(HapussBarang barang) async {
    try {
      final response = await _dio.delete('/barang/hapus/${barang.nama}');
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleteBarang: $e");
      return false;
    }
  }

  // Export Excel
  static Future<Response?> exportExcel() async {
    try {
      final response = await _dio.get(
        '/barang/laporan/export-excel',
        options: Options(responseType: ResponseType.bytes),
      );
      return response;
    } catch (e) {
      print("Error exportExcel: $e");
      return null;
    }
  }
}
