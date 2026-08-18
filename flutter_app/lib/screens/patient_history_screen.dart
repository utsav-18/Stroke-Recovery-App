import 'package:flutter/material.dart';

import '../models/exercise_session.dart';
import '../services/api_service.dart';

class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({super.key});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  List<ExerciseSession> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      final sessions = await ApiService().getPatientSessions();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
              : _sessions.isEmpty
                  ? const Center(child: Text('No history found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
          final movementStatus = session.movementStatus ?? 'Not Improved';
          final confidence = (session.confidenceScore ?? 0.0) * 100;
          final emotion = session.emotion ?? 'No Face Detected';
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111C2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF24314A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        session.exerciseType,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    _Badge(label: movementStatus),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${session.startedAt.toLocal().toString().split(' ').first} • ${session.startedAt.toLocal().toString().substring(11, 16)}',
                  style: const TextStyle(color: Color(0xFF9FB1CA)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Confidence: ${confidence.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 18),
                    Text('Emotion: $emotion', style: const TextStyle(color: Color(0xFFB7C8D9))),
                  ],
                ),
              ],
            ),
          );
                      },
                    ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label.toLowerCase()) {
      String value when value.contains('improved') => const Color(0xFF22C55E),
      String value when value.contains('improving') => const Color(0xFFEAB308),
      _ => const Color(0xFFEF4444),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
