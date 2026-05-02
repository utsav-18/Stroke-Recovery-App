import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/analyze_result.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = const [];

  bool _isCameraLoading = true;
  bool _isRecording = false;
  bool _isUploading = false;

  File? _savedVideoFile;
  AnalyzeResult? _result;
  String? _cameraError;
  String? _message;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) {
        return;
      }

      _availableCameras = cameras;
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No camera found on this device.';
          _isCameraLoading = false;
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraError = 'Camera initialization failed: $error';
        _isCameraLoading = false;
      });
    }
  }

  Future<void> _toggleRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _showSnackBar('Camera is not ready yet.');
      return;
    }

    try {
      setState(() {
        _errorMessage = null;
        _message = null;
      });

      if (controller.value.isRecordingVideo) {
        final recordedFile = await controller.stopVideoRecording();
        final savedFile = await _saveVideoLocally(recordedFile.path);

        if (!mounted) {
          return;
        }

        setState(() {
          _isRecording = false;
          _savedVideoFile = savedFile;
          _result = null;
          _message = 'Video saved locally at ${savedFile.path}';
        });

        _showSnackBar('Recording stopped and saved locally.');
        return;
      }

      await controller.startVideoRecording();
      if (!mounted) {
        return;
      }

      setState(() {
        _isRecording = true;
        _result = null;
        _message = 'Recording in progress...';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRecording = false;
        _errorMessage = 'Could not record video: $error';
      });
      _showSnackBar('Recording error: $error');
    }
  }

  Future<File> _saveVideoLocally(String sourcePath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final videosDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}stroke_videos',
    );

    if (!await videosDirectory.exists()) {
      await videosDirectory.create(recursive: true);
    }

    final fileName = 'exercise_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final destinationPath =
        '${videosDirectory.path}${Platform.pathSeparator}$fileName';

    return File(sourcePath).copy(destinationPath);
  }

  Future<void> _uploadAndAnalyze() async {
    if (_isRecording) {
      await _toggleRecording();
    }

    final videoFile = _savedVideoFile;
    if (videoFile == null) {
      _showSnackBar('Record a video before uploading.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _message = 'Uploading video for analysis...';
      _result = null;
    });

    try {
      final result = await _apiService.uploadVideo(videoFile);
      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _message = 'Analysis complete.';
      });
      _showSnackBar('Analysis completed successfully.');
    } on FileSystemException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } on SocketException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } on HttpException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unexpected error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showSnackBar(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('improved')) {
      return const Color(0xFF0F766E);
    }
    if (normalized.contains('improving')) {
      return const Color(0xFFB45309);
    }
    return const Color(0xFFB91C1C);
  }

  String _formatConfidence(double value) {
    if (value <= 1) {
      return '${(value * 100).toStringAsFixed(1)}%';
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final cameraController = _cameraController;
    final cameraReady = cameraController != null && cameraController.value.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stroke Recovery Monitor'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildCameraCard(cameraController, cameraReady),
              const SizedBox(height: 16),
              _buildActionButtons(cameraReady),
              const SizedBox(height: 16),
              _buildStatusSection(),
              const SizedBox(height: 16),
              _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      color: const Color(0xFFEAF5F4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stroke Recovery Monitoring',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF12312E),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Record a rehabilitation exercise, save the clip locally, and upload it to your FastAPI backend for analysis.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF44605D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraCard(CameraController? cameraController, bool cameraReady) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Camera Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF12312E),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 260,
                color: const Color(0xFF0F172A),
                alignment: Alignment.center,
                child: _isCameraLoading
                    ? const CircularProgressIndicator()
                    : _cameraError != null
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _cameraError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          )
                        : cameraReady
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  CameraPreview(cameraController!),
                                  if (_isRecording)
                                    const Positioned(
                                      top: 14,
                                      left: 14,
                                      child: _RecordingBadge(),
                                    ),
                                ],
                              )
                            : const Center(
                                child: Text(
                                  'Camera is preparing...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
              ),
            ),
            if (_availableCameras.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Available cameras: ${_availableCameras.length}',
                style: const TextStyle(color: Color(0xFF5A6F6B)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool cameraReady) {
    final recordButtonEnabled = cameraReady && !_isUploading;
    final uploadButtonEnabled = !_isUploading;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: recordButtonEnabled ? _toggleRecording : null,
            icon: Icon(_isRecording ? Icons.stop_circle_outlined : Icons.videocam_outlined),
            label: Text(_isRecording ? 'Stop Recording' : 'Record Exercise'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: uploadButtonEnabled ? _uploadAndAnalyze : null,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Upload & Analyze'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    if (_isUploading) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Uploading and analyzing your video...',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        elevation: 0,
        color: const Color(0xFFFFF1F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFF7F1D1D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_message != null) {
      return Card(
        elevation: 0,
        color: const Color(0xFFEFFCF8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _message!,
            style: const TextStyle(
              color: Color(0xFF14532D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Status updates will appear here after recording or uploading.',
          style: TextStyle(color: Color(0xFF5A6F6B)),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    if (_result == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Result',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF12312E),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your movement analysis will appear here after the backend responds.',
                style: TextStyle(color: Color(0xFF5A6F6B)),
              ),
            ],
          ),
        ),
      );
    }

    final statusColor = _statusColor(_result!.movementStatus);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Result',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF12312E),
              ),
            ),
            const SizedBox(height: 16),
            _ResultMetricCard(
              title: 'Movement Status',
              value: _result!.movementStatus,
              valueColor: statusColor,
            ),
            const SizedBox(height: 12),
            _ResultMetricCard(
              title: 'Confidence Score',
              value: _formatConfidence(_result!.confidenceScore),
              valueColor: const Color(0xFF0F766E),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingBadge extends StatelessWidget {
  const _RecordingBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text(
              'Recording',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMetricCard extends StatelessWidget {
  const _ResultMetricCard({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  final String title;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A6F6B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
