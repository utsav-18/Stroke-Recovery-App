import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../models/patient.dart';
import '../models/progress.dart';
import '../models/user.dart';

class ApiService {
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // --- Auth ---

  Future<UserModel> login({required String email, required String password}) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data;
      await _storage.write(key: _tokenKey, value: data['token'] as String);
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'name': name, 'role': role},
      );
      final data = response.data;
      await _storage.write(key: _tokenKey, value: data['token'] as String);
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return null;
      final response = await _dio.get('/auth/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
        return null;
      }
      throw _handleError(e);
    }
  }

  // --- Doctors ---

  Future<Map<String, dynamic>> getDoctorMe() async {
    try {
      final response = await _dio.get('/doctors/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateDoctorMe({
    required String name,
    String? specialization,
    String? phone,
  }) async {
    try {
      final response = await _dio.put(
        '/doctors/me',
        data: {
          'name': name,
          'specialization': specialization,
          'phone': phone,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAssignedPatients() async {
    try {
      final response = await _dio.get('/doctors/me/patients');
      return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Patient> getPatientDetail(int patientId) async {
    try {
      final response = await _dio.get('/doctors/me/patients/$patientId');
      return Patient.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ProgressSummary> getPatientProgressForDoctor(int patientId) async {
    try {
      final response = await _dio.get('/doctors/me/patients/$patientId/progress');
      return ProgressSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    final response = error.response;
    if (response != null) {
      final responseBody = response.data;
      String message = 'Server error (${response.statusCode})';
      
      if (responseBody is Map && responseBody.containsKey('detail')) {
        message = responseBody['detail'].toString();
      } else {
        message = responseBody?.toString() ?? message;
      }
      return Exception(message);
    }
    return Exception('Failed to connect: ${error.message ?? 'request failed'}');
  }
}
