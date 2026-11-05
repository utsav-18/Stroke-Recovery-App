import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../services/api_service.dart';
import 'analysis_result_screen.dart';

class ExerciseFlowScreen extends StatefulWidget {
  const ExerciseFlowScreen({
    super.key,
    this.assignedLevel = 1,
    this.patientCode,
  });

  final int assignedLevel;
  final String? patientCode;

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
      if (source == ImageSource.camera) {
        setState(() {
          _statusMessage = 'Transmitting level ${widget.assignedLevel} start trigger to VR game...';
        });
        try {
          await _apiService.triggerGameStart();
        } catch (e) {
          debugPrint('Game trigger warning: $e');
        }
      }

      final picked = await _imagePicker.pickVideo(source: source);
      if (picked == null) {
        setState(() => _statusMessage = null);
        return;
      }

      final file = File(picked.path);
      if (!await file.exists()) {
        setState(() => _errorMessage = 'Selected recording file could not be accessed.');
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
      setState(() => _errorMessage = 'Failed to capture or read exercise video: $error');
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
      _statusMessage = 'Uploading video & computing upper-limb biomechanics...';
    });

    try {
      final session = await _apiService.createSession(
        exerciseType: 'Level ${widget.assignedLevel} Protocol Session',
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
      setState(() => _errorMessage = 'Analysis pipeline failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Clinical Motion Recording',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
      ),
      body: SafeArea(
        child: _selectedVideo == null ? _buildSelectionState() : _buildPreviewState(),
      ),
    );
  }

  Widget _buildSelectionState() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment_outlined, color: Color(0xFF0D47A1), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'PRESCRIBED PROTOCOL: LEVEL ${widget.assignedLevel}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D47A1),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Position camera to capture entire upper-body.\n2. Tap below to synchronize VR game and start camera.\n3. Upon completion, telemetry is sent to physician dashboard.',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: const Color(0xFF0D47A1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _pickVideo(ImageSource.camera),
            icon: const Icon(Icons.videocam_rounded, size: 24),
            label: const Text('Start VR Session & Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFCBD5E1))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('OR', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              Expanded(child: Divider(color: Color(0xFFCBD5E1))),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _pickVideo(ImageSource.gallery),
            icon: const Icon(Icons.upload_file_outlined, size: 20, color: Color(0xFF475569)),
            label: const Text('Select Existing Video File', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.video_library_outlined, size: 18, color: Color(0xFF0D47A1)),
              const SizedBox(width: 8),
              const Text(
                'Recorded Session Review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              Text(
                'Level ${widget.assignedLevel}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1))),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedVideo!.path.split(Platform.pathSeparator).last,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D47A1))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  child: const Text('Discard & Re-Record', style: TextStyle(color: Color(0xFF475569))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isUploading ? null : _analyzeVideo,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF059669),
                  ),
                  icon: _isUploading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isUploading ? 'Analyzing...' : 'Complete & Send'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
