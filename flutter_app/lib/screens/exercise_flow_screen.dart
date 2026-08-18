import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../services/api_service.dart';
import 'analysis_result_screen.dart';

class ExerciseFlowScreen extends StatefulWidget {
  const ExerciseFlowScreen({super.key});

  @override
  State<ExerciseFlowScreen> createState() => _ExerciseFlowScreenState();
}

class _ExerciseFlowScreenState extends State<ExerciseFlowScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isUploading = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickVideo(source: source);
      if (picked == null) return;

      final file = File(picked.path);
      if (!await file.exists()) {
        setState(() => _errorMessage = 'Selected video could not be found.');
        return;
      }

      await _videoController?.dispose();
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.setLooping(true);
      controller.play();

      setState(() {
        _selectedVideo = file;
        _videoController = controller;
        _errorMessage = null;
        _statusMessage = null;
      });
    } catch (error) {
      setState(() => _errorMessage = 'Could not process video: $error');
    }
  }

  void _clearSelection() {
    _videoController?.pause();
    _videoController?.dispose();
    setState(() {
      _selectedVideo = null;
      _videoController = null;
      _errorMessage = null;
      _statusMessage = null;
    });
  }

  Future<void> _analyzeVideo() async {
    if (_selectedVideo == null) return;
    if (_isUploading) return;

    _videoController?.pause();

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _statusMessage = 'Uploading and analyzing...';
    });

    try {
      final session = await _apiService.createSession(
        exerciseType: 'General Exercise',
        startedAt: DateTime.now(),
      );

      final result = await _apiService.uploadVideo(
        _selectedVideo!,
        sessionId: session.id,
      );
      
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(result: result),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Upload failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Analysis')),
      body: SafeArea(
        child: _selectedVideo == null ? _buildSelectionState() : _buildPreviewState(),
      ),
    );
  }

  Widget _buildSelectionState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Record your rehabilitation\nexercise video',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 48),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: const Color(0xFF2F80FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => _pickVideo(ImageSource.camera),
            icon: const Icon(Icons.videocam_rounded, size: 28),
            label: const Text('Start Recording', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFF24314A))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(color: Color(0xFF9FB1CA), fontWeight: FontWeight.w700)),
              ),
              Expanded(child: Divider(color: Color(0xFF24314A))),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              side: const BorderSide(color: Color(0xFF2F80FF), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => _pickVideo(ImageSource.gallery),
            icon: const Icon(Icons.folder_open_rounded, size: 28),
            label: const Text('Upload Video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B1118),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFFCA5A5)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Selected Video',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF24314A)),
              ),
              child: _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedVideo!.path.split(Platform.pathSeparator).last,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF9FB1CA)),
          ),
          const SizedBox(height: 24),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1F1A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(color: Color(0xFFA7F3D0)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B1118),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFFCA5A5)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isUploading ? null : _clearSelection,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF24314A), width: 2),
                  ),
                  child: const Text('Record Again', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isUploading ? null : _analyzeVideo,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                  icon: _isUploading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded),
                  label: Text(_isUploading ? 'Analyzing...' : 'Use Video'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
