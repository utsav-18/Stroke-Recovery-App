import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../models/progress.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'exercise_flow_screen.dart';
import 'patient_history_screen.dart';
import 'patient_progress_screen.dart';
import 'profile_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _secondary = Color(0xFF0284C7);

  UserModel? _user;
  Patient? _patient;
  ProgressSummary? _progress;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final api = ApiService();
      final user = await api.getCurrentUser();
      if (user == null) {
        throw Exception('Session expired');
      }
      Patient? patient;
      try {
        patient = await api.getPatientMe();
      } catch (_) {}

      final progress = await api.getPatientProgress();
      if (mounted) {
        setState(() {
          _user = user;
          _patient = patient;
          _progress = progress;
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2.5, color: _primary),
              SizedBox(height: 14),
              Text(
                'Loading Patient Clinical Records...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _user == null || _progress == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 36),
                const SizedBox(height: 12),
                Text(
                  'Error loading clinical dashboard: $_errorMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _fetchData();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final latestResult = _progress!.latestMovementStatus;
    final averageConfidence = _progress!.averageConfidence;
    final emotion = _progress!.emotionHistory.isNotEmpty ? _progress!.emotionHistory.first.emotion : 'Baseline';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RehabTrack Clinical Suite',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Patient ID: ${_patient?.patientCode ?? 'PT-REC'}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF475569)),
            tooltip: 'Clinical Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WelcomeCard(
                name: _user!.name,
                patientCode: _patient?.patientCode ?? '',
                progressLabel: '${_progress!.totalSessions} clinical sessions completed',
              ),
              const SizedBox(height: 14),
              _PrescribedLevelBanner(
                assignedLevel: _patient?.assignedLevel ?? 1,
                patientCode: _patient?.patientCode ?? '',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      title: 'Start VR Session',
                      subtitle: 'Record & trigger VR level ${_patient?.assignedLevel ?? 1}',
                      icon: Icons.videogame_asset_outlined,
                      accent: _primary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ExerciseFlowScreen(
                              assignedLevel: _patient?.assignedLevel ?? 1,
                              patientCode: _patient?.patientCode,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FeatureCard(
                      title: 'Session History',
                      subtitle: 'Review kinematic records',
                      icon: Icons.assignment_outlined,
                      accent: _secondary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const PatientHistoryScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MetricCard(
                title: 'Most Recent Movement Analysis',
                movementStatus: latestResult,
                confidenceScore: averageConfidence,
                emotion: emotion,
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                title: 'Rehabilitation Telemetry Overview',
                confidence: _progress!.averageConfidence,
                movementStatus: _progress!.latestMovementStatus,
                sessions: _progress!.totalSessions,
              ),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'Recovery Trajectory',
                subtitle: 'Detailed angular trends and kinematic metrics',
                icon: Icons.analytics_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PatientProgressScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ActionCard(
                title: 'Medical Profile & Prescriptions',
                subtitle: 'Supervising physician and recovery plan',
                icon: Icons.badge_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.name,
    required this.patientCode,
    required this.progressLabel,
  });

  final String name;
  final String patientCode;
  final String progressLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFF0D47A1), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (patientCode.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          patientCode,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  progressLabel,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: accent.withValues(alpha: 0.08),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.movementStatus,
    required this.confidenceScore,
    required this.emotion,
  });

  final String title;
  final String movementStatus;
  final double confidenceScore;
  final String emotion;

  @override
  Widget build(BuildContext context) {
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
              Text(
                title.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const Icon(Icons.health_and_safety_outlined, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ClinicalBadge(label: movementStatus, color: _movementColor(movementStatus)),
              const Spacer(),
              Text(
                '${(confidenceScore * 100).toStringAsFixed(0)}% Confidence',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.mood_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'Facial Affect: $emotion',
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _movementColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('improved')) return const Color(0xFF059669);
    if (normalized.contains('improving')) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.confidence,
    required this.movementStatus,
    required this.sessions,
  });

  final String title;
  final double confidence;
  final String movementStatus;
  final int sessions;

  @override
  Widget build(BuildContext context) {
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
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(value: '${(confidence * 100).toStringAsFixed(0)}%', label: 'Confidence Score'),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: _MiniStat(value: movementStatus, label: 'Current State'),
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: _MiniStat(value: '$sessions', label: 'Sessions Run'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF0D47A1), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}

class _ClinicalBadge extends StatelessWidget {
  const _ClinicalBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PrescribedLevelBanner extends StatelessWidget {
  const _PrescribedLevelBanner({
    required this.assignedLevel,
    required this.patientCode,
  });

  final int assignedLevel;
  final String patientCode;

  static const _descriptions = {
    1: 'Mild Range of Motion & Planar Reaching',
    2: 'Arm Elevation by Shoulder & Elbow Flexion',
    3: 'Target Coordination & Multi-Axis Distance',
    4: 'Resistance & Dynamic Motor Control',
    5: 'Full Upper-Limb Active Kinetic Range',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Hospital soft clinical blue
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PRESCRIBED PROTOCOL: LEVEL $assignedLevel',
                      style: const TextStyle(
                        color: Color(0xFF0D47A1),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (patientCode.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '($patientCode)',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _descriptions[assignedLevel] ?? 'Rehabilitation Exercise',
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
