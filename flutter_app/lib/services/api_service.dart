import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:video_compress/video_compress.dart';

import '../config/app_config.dart';
import '../models/analyze_result.dart';
import '../models/exercise_session.dart';
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

  // --- Patients ---

  Future<Patient> getPatientMe() async {
    try {
      final response = await _dio.get('/patients/me');
      return Patient.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Patient> updatePatientMe({
    required String name,
    String? dateOfBirth,
    String? gender,
    String? phone,
  }) async {
    try {
      final response = await _dio.put(
        '/patients/me',
        data: {
          'name': name,
          'date_of_birth': dateOfBirth,
          'gender': gender,
          'phone': phone,
        },
      );
      return Patient.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ExerciseSession>> getPatientSessions() async {
    try {
      final response = await _dio.get('/patients/me/sessions');
      final list = response.data as List<dynamic>;
      return list.map((e) => ExerciseSession.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ProgressSummary> getPatientProgress() async {
    try {
      final response = await _dio.get('/patients/me/progress');
      return ProgressSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ExerciseSession> createSession({
    required String exerciseType,
    required DateTime startedAt,
  }) async {
    try {
      final response = await _dio.post(
        '/patients/me/sessions',
        data: {
          'exercise_type': exerciseType,
          'started_at': startedAt.toUtc().toIso8601String(),
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
      return ExerciseSession.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- Analysis ---

  Future<AnalyzeResult> uploadVideo(File video, {int? sessionId}) async {
    if (!await video.exists()) {
      throw const FileSystemException('Video file not found.');
    }

    try {
      final compressedVideo = await _compressVideo(video);
      final fileName = compressedVideo.path.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressedVideo.path,
          filename: fileName,
          contentType: MediaType('video', 'mp4'),
        ),
        if (sessionId != null) 'session_id': sessionId.toString(),
      });

      final response = await _dio.post<dynamic>(
        '/analyze',
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw HttpException(
          'Server error: ${response.statusCode ?? 'unknown status'}',
        );
      }

      return _parseAnalyzeResult(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    } on FormatException {
      rethrow;
    } on SocketException {
      rethrow;
    } on FileSystemException {
      rethrow;
    } catch (error) {
      throw Exception('Failed to connect: $error');
    }
  }

  Future<File> _compressVideo(File video) async {
    final mediaInfo = await VideoCompress.compressVideo(
      video.path,
      quality: VideoQuality.Res640x480Quality,
      deleteOrigin: false,
      includeAudio: true,
      frameRate: 30,
    );

    final compressedFile = mediaInfo?.file;
    if (compressedFile == null || !await compressedFile.exists()) {
      throw Exception('Failed to compress video file.');
    }

    return compressedFile;
  }

  AnalyzeResult _parseAnalyzeResult(dynamic data) {
    if (data is Map<String, dynamic>) {
      return AnalyzeResult.fromJson(data);
    }

    if (data is Map) {
      return AnalyzeResult.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return AnalyzeResult.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    }

    throw const FormatException('Invalid response format from server.');
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
