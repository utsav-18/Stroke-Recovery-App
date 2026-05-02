import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:video_compress/video_compress.dart';

import '../models/analyze_result.dart';

class ApiService {
  ApiService({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: _resolveBaseUrl(baseUrl),
            connectTimeout: const Duration(seconds: 120),
            receiveTimeout: const Duration(seconds: 120),
            sendTimeout: const Duration(seconds: 120),
          ),
        );

  final Dio _dio;

  static String _resolveBaseUrl(String? baseUrl) {
    final resolvedBaseUrl =
        baseUrl ??
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.1.32.171:8000',
        );
    print('API Base URL: $resolvedBaseUrl');
    return resolvedBaseUrl;
  }

  Future<AnalyzeResult> uploadVideo(File video) async {
    if (!await video.exists()) {
      throw const FileSystemException('Video file not found.');
    }

    try {
      final originalSize = await video.length();
      print('Original size: $originalSize bytes');

      final compressedVideo = await _compressVideo(video);
      final compressedSize = await compressedVideo.length();
      print('Compressed size: $compressedSize bytes');

      final fileName = compressedVideo.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressedVideo.path,
          filename: fileName,
          contentType: MediaType('video', 'mp4'),
        ),
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
    } on DioException catch (error) {
      print('API ERROR: $error');

      final response = error.response;
      if (response != null) {
        final responseBody = response.data;
        final bodyText = responseBody is Map || responseBody is List
            ? jsonEncode(responseBody)
            : responseBody?.toString() ?? 'No response body';

        throw Exception(
          'Failed to connect: Server error (${response.statusCode}): $bodyText',
        );
      }

      throw Exception(
        'Failed to connect: ${error.message ?? 'request failed'}',
      );
    } on FormatException {
      rethrow;
    } on SocketException {
      rethrow;
    } on FileSystemException {
      rethrow;
    } catch (error) {
      print('API ERROR: $error');
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
