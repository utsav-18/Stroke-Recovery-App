import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../models/analyze_result.dart';

class ApiService {
  ApiService({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            // Use 10.0.2.2 on the Android emulator. Replace it with your PC's LAN IP for a real device.
            baseUrl: baseUrl ?? const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000',
            ),
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            contentType: 'multipart/form-data',
          ),
        );

  final Dio _dio;

  Future<AnalyzeResult> uploadVideo(File video) async {
    if (!await video.exists()) {
      throw const FileSystemException('Video file not found.');
    }

    try {
      final fileName = video.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          video.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post<dynamic>(
        '/analyze',
        data: formData,
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw HttpException(
          'Server error: ${response.statusCode ?? 'unknown status'}',
        );
      }

      return _parseAnalyzeResult(response.data);
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        throw const SocketException(
          'Network error: unable to reach the analysis backend.',
        );
      }

      final response = error.response;
      if (response != null) {
        final responseBody = response.data;
        final bodyText = responseBody is Map || responseBody is List
            ? jsonEncode(responseBody)
            : responseBody?.toString() ?? 'No response body';

        throw HttpException(
          'Server error (${response.statusCode}): $bodyText',
        );
      }

      throw HttpException('Network error: ${error.message ?? 'request failed'}');
    } on FormatException {
      rethrow;
    } on SocketException {
      rethrow;
    } on FileSystemException {
      rethrow;
    } catch (error) {
      throw FormatException('Unexpected error while analyzing video: $error');
    }
  }

  AnalyzeResult _parseAnalyzeResult(dynamic data) {
    if (data is Map<String, dynamic>) {
      return AnalyzeResult.fromJson(data);
    }

    if (data is Map) {
      return AnalyzeResult.fromJson(
        data.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    }

    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return AnalyzeResult.fromJson(
          decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        );
      }
    }

    throw const FormatException('Invalid response format from server.');
  }
}
