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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Clinical Motion Session Log',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0D47A1)),
                  SizedBox(height: 14),
                  Text('Loading Session Logs...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                  ),
                )
              : _sessions.isEmpty
                  ? const Center(
                      child: Text('No historical session records found.', style: TextStyle(color: Color(0xFF64748B))),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final movementStatus = session.movementStatus ?? 'Baseline';
                        final confidence = (session.confidenceScore ?? 0.0) * 100;
                        final emotion = session.emotion ?? 'Neutral';
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x04000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
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
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  _ClinicalBadge(label: movementStatus),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${session.startedAt.toLocal().toString().split(' ').first} at ${session.startedAt.toLocal().toString().substring(11, 16)}',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.auto_graph_rounded, size: 14, color: Color(0xFF0D47A1)),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Confidence: ${confidence.toStringAsFixed(0)}%',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0D47A1)),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.mood_outlined, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Affect: $emotion',
                                    style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
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

class _ClinicalBadge extends StatelessWidget {
  const _ClinicalBadge({required this.label});

  final String label;

  Color _color() {
    final lower = label.toLowerCase();
    if (lower.contains('improved')) return const Color(0xFF059669);
    if (lower.contains('improving')) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}
