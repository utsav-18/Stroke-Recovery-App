import 'package:flutter/material.dart';

import '../models/progress.dart';
import '../services/api_service.dart';

class PatientProgressScreen extends StatefulWidget {
  const PatientProgressScreen({super.key});

  @override
  State<PatientProgressScreen> createState() => _PatientProgressScreenState();
}

class _PatientProgressScreenState extends State<PatientProgressScreen> {
  ProgressSummary? _progress;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    try {
      final progress = await ApiService().getPatientProgress();
      if (mounted) {
        setState(() {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
              : _progress == null
                  ? const Center(child: Text('No progress data.'))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _TrendCard(
                          title: 'Confidence Trend',
                          icon: Icons.trending_up_rounded,
                          trend: _progress!.confidenceTrend,
                        ),
                        const SizedBox(height: 16),
                        _HistoryCard(
                          title: 'Movement History',
                          icon: Icons.timeline_rounded,
                          history: _progress!.movementHistory,
                        ),
                        const SizedBox(height: 16),
                        _EmotionCard(
                          title: 'Recent Emotion Results',
                          icon: Icons.mood_rounded,
                          history: _progress!.emotionHistory,
                        ),
                        const SizedBox(height: 16),
                        _MiniGrid(
                          totalSessions: _progress!.totalSessions,
                          latestStatus: _progress!.latestMovementStatus,
                          averageConfidence: _progress!.averageConfidence,
                        ),
                      ],
                    ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.title, required this.icon, required this.trend});

  final String title;
  final IconData icon;
  final List<double> trend;

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: title,
      icon: icon,
      child: trend.isEmpty
          ? const Text('No confidence data yet', style: TextStyle(color: Color(0xFFB7C8D9)))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trend.map((v) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C375E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(v * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF61E4C5)),
                ),
              )).toList(),
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.title, required this.icon, required this.history});

  final String title;
  final IconData icon;
  final List<MovementTrendPoint> history;

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: title,
      icon: icon,
      child: history.isEmpty
          ? const Text('No movement data yet', style: TextStyle(color: Color(0xFFB7C8D9)))
          : Column(
              children: history.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.date, style: const TextStyle(color: Color(0xFF9FB1CA))),
                    Text(entry.status, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              )).toList(),
            ),
    );
  }
}

class _EmotionCard extends StatelessWidget {
  const _EmotionCard({required this.title, required this.icon, required this.history});

  final String title;
  final IconData icon;
  final List<EmotionTrendPoint> history;

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: title,
      icon: icon,
      child: history.isEmpty
          ? const Text('No emotion data yet', style: TextStyle(color: Color(0xFFB7C8D9)))
          : Column(
              children: history.map((entry) {
                final emoji = _getEmoji(entry.emotion);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.emotion, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white))),
                      Text(entry.date, style: const TextStyle(color: Color(0xFF9FB1CA))),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  String _getEmoji(String emotion) {
    final lower = emotion.toLowerCase();
    if (lower.contains('happy')) return '🙂';
    if (lower.contains('sad')) return '😢';
    if (lower.contains('angry')) return '😠';
    if (lower.contains('neutral')) return '😐';
    return '😶';
  }
}

class _BaseCard extends StatelessWidget {
  const _BaseCard({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

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
          Row(
            children: [
              Icon(icon, color: const Color(0xFF61E4C5)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MiniGrid extends StatelessWidget {
  const _MiniGrid({
    required this.totalSessions,
    required this.latestStatus,
    required this.averageConfidence,
  });

  final int totalSessions;
  final String latestStatus;
  final double averageConfidence;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniTile(label: 'Sessions', value: '$totalSessions')),
        const SizedBox(width: 12),
        Expanded(child: _MiniTile(label: 'Status', value: latestStatus)),
        const SizedBox(width: 12),
        Expanded(child: _MiniTile(label: 'Avg', value: '${(averageConfidence * 100).toStringAsFixed(0)}%')),
      ],
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1624),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF24314A)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF96A9C2))),
          ),
        ],
      ),
    );
  }
}
