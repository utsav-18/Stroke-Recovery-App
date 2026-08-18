import 'package:flutter/material.dart';

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

  static const Color _teal = Color(0xFF61E4C5);
  static const Color _primary = Color(0xFF2F80FF);

  UserModel? _user;
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
        throw Exception('Not logged in');
      }
      final progress = await api.getPatientProgress();
      if (mounted) {
        setState(() {
          _user = user;
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _user == null || _progress == null) {
      return Scaffold(
        body: Center(
          child: Text('Error loading dashboard: $_errorMessage', style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    final latestResult = _progress!.latestMovementStatus;
    final averageConfidence = _progress!.averageConfidence;
    final emotion = _progress!.emotionHistory.isNotEmpty ? _progress!.emotionHistory.first.emotion : 'No Data';

    return Scaffold(
      appBar: AppBar(
        title: const Text('RehabTrack'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WelcomeCard(
                name: _user!.name,
                progressLabel: '${_progress!.totalSessions} sessions logged',
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      title: 'Start Exercise',
                      subtitle: 'Record or upload a video',
                      icon: Icons.videocam_rounded,
                      accent: _primary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const ExerciseFlowScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FeatureCard(
                      title: 'History',
                      subtitle: 'Review sessions',
                      icon: Icons.history_rounded,
                      accent: _teal,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const PatientHistoryScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MetricCard(
                title: 'Latest result',
                movementStatus: latestResult,
                confidenceScore: averageConfidence,
                emotion: emotion,
              ),
              const SizedBox(height: 18),
              _SummaryCard(
                title: 'Progress summary',
                confidence: _progress!.averageConfidence,
                movementStatus: _progress!.latestMovementStatus,
                sessions: _progress!.totalSessions,
              ),
              const SizedBox(height: 18),
              _ActionCard(
                title: 'Progress',
                subtitle: 'Review trends and recent recovery steps',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PatientProgressScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                title: 'Profile',
                subtitle: 'View account and recovery details',
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
  const _WelcomeCard({required this.name, required this.progressLabel});

  final String name;
  final String progressLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF10213D), Color(0xFF1C375E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2F80FF).withValues(alpha: 0.18),
            ),
            child: const Icon(Icons.favorite_rounded, color: Color(0xFF61E4C5)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  progressLabel,
                  style: const TextStyle(color: Color(0xFFB7C8D9)),
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
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF111C2E),
          border: Border.all(color: const Color(0xFF24314A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Color(0xFFB7C8D9), fontSize: 12)),
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
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF24314A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF9FB1CA))),
          const SizedBox(height: 12),
          Row(
            children: [
              _Badge(label: movementStatus, color: _movementColor(movementStatus)),
              const SizedBox(width: 10),
              Text('${(confidenceScore * 100).toStringAsFixed(0)}% confidence',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Emotion: $emotion', style: const TextStyle(color: Color(0xFFD9E7F7))),
        ],
      ),
    );
  }

  Color _movementColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('improved')) return const Color(0xFF22C55E);
    if (normalized.contains('improving')) return const Color(0xFFEAB308);
    return const Color(0xFFEF4444);
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
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF24314A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF9FB1CA))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(value: '${(confidence * 100).toStringAsFixed(0)}%', label: 'Avg confidence'),
              ),
              Expanded(
                child: _MiniStat(value: movementStatus, label: 'Movement'),
              ),
              Expanded(
                child: _MiniStat(value: '$sessions', label: 'Sessions'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111C2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF24314A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline_rounded, color: Color(0xFF61E4C5)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Color(0xFFB7C8D9))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Color(0xFF9FB1CA), fontSize: 11)),
      ],
    );
  }
}
