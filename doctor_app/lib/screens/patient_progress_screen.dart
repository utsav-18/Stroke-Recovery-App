import 'package:flutter/material.dart';

import '../models/progress.dart';
import '../services/api_service.dart';

class PatientProgressScreen extends StatefulWidget {
  const PatientProgressScreen({super.key, required this.patientId});

  final int patientId;

  @override
  State<PatientProgressScreen> createState() => _PatientProgressScreenState();
}

class _PatientProgressScreenState extends State<PatientProgressScreen> {
  ProgressSummary? _progress;
  bool _isLoading = true;
  String? _errorMessage;
  int? _currentLevel;
  bool _isUpdatingLevel = false;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    try {
      final progress = await ApiService().getPatientProgressForDoctor(widget.patientId);
      if (mounted) {
        setState(() {
          _progress = progress;
          _currentLevel = progress.assignedLevel;
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

  Future<void> _updateLevel(int newLevel) async {
    if (_isUpdatingLevel || _currentLevel == newLevel) return;
    setState(() => _isUpdatingLevel = true);
    try {
      await ApiService().assignPatientLevel(widget.patientId, newLevel);
      if (mounted) {
        setState(() {
          _currentLevel = newLevel;
          _isUpdatingLevel = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prescribed Level $newLevel to patient'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingLevel = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update prescription: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
          'Kinematic Analysis & Prescription',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0D47A1)),
                  SizedBox(height: 14),
                  Text('Loading Kinematic Telemetry...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
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
              : _progress == null
                  ? const Center(child: Text('No rehabilitation records available.'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      children: [
                        _LevelAssignmentCard(
                          currentLevel: _currentLevel ?? _progress!.assignedLevel,
                          gameStatus: _progress!.gameStatus,
                          isUpdating: _isUpdatingLevel,
                          onLevelSelected: _updateLevel,
                        ),
                        const SizedBox(height: 14),
                        _MiniGrid(
                          totalSessions: _progress!.totalSessions,
                          latestStatus: _progress!.latestMovementStatus,
                          averageConfidence: _progress!.averageConfidence,
                        ),
                        const SizedBox(height: 14),
                        _TrendCard(
                          title: 'Confidence Index History',
                          icon: Icons.trending_up_rounded,
                          trend: _progress!.confidenceTrend,
                        ),
                        const SizedBox(height: 14),
                        _HistoryCard(
                          title: 'Rehabilitation Session Trajectory',
                          icon: Icons.history_rounded,
                          history: _progress!.movementHistory,
                        ),
                        const SizedBox(height: 14),
                        _EmotionCard(
                          title: 'Affect & Emotion Observations',
                          icon: Icons.psychology_outlined,
                          history: _progress!.emotionHistory,
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
          ? const Text('No confidence trajectory logged yet', style: TextStyle(color: Color(0xFF64748B), fontSize: 13))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trend.map((v) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  '${(v * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1), fontSize: 13),
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
          ? const Text('No session movement records yet', style: TextStyle(color: Color(0xFF64748B), fontSize: 13))
          : Column(
              children: history.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.date, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                    _ClinicalStatusPill(label: entry.status),
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
          ? const Text('No facial affect telemetry recorded', style: TextStyle(color: Color(0xFF64748B), fontSize: 13))
          : Column(
              children: history.map((entry) {
                final iconData = _getEmotionIcon(entry.emotion);
                final iconColor = _getEmotionColor(entry.emotion);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, size: 18, color: iconColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.emotion,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A), fontSize: 13),
                        ),
                      ),
                      Text(entry.date, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  IconData _getEmotionIcon(String emotion) {
    final lower = emotion.toLowerCase();
    if (lower.contains('happy')) return Icons.sentiment_satisfied_alt_outlined;
    if (lower.contains('sad')) return Icons.sentiment_dissatisfied_outlined;
    if (lower.contains('angry')) return Icons.sentiment_very_dissatisfied_outlined;
    if (lower.contains('neutral')) return Icons.sentiment_neutral_outlined;
    return Icons.mood_outlined;
  }

  Color _getEmotionColor(String emotion) {
    final lower = emotion.toLowerCase();
    if (lower.contains('happy')) return const Color(0xFF059669);
    if (lower.contains('sad')) return const Color(0xFF0284C7);
    if (lower.contains('angry')) return const Color(0xFFDC2626);
    return const Color(0xFF64748B);
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
            children: [
              Icon(icon, color: const Color(0xFF0D47A1), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
        Expanded(child: _MiniTile(label: 'Total Sessions', value: '$totalSessions')),
        const SizedBox(width: 10),
        Expanded(child: _MiniTile(label: 'Latest Outcome', value: latestStatus)),
        const SizedBox(width: 10),
        Expanded(child: _MiniTile(label: 'Confidence Avg', value: '${(averageConfidence * 100).toStringAsFixed(0)}%')),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelAssignmentCard extends StatelessWidget {
  const _LevelAssignmentCard({
    required this.currentLevel,
    required this.gameStatus,
    required this.isUpdating,
    required this.onLevelSelected,
  });

  final int currentLevel;
  final String gameStatus;
  final bool isUpdating;
  final ValueChanged<int> onLevelSelected;

  static const _levelDescriptions = {
    1: 'Mild Range of Motion & Planar Reaching',
    2: 'Arm Elevation by Shoulder & Elbow Flexion',
    3: 'Target Coordination & Reach Distance',
    4: 'Resistance & Dynamic Motor Control',
    5: 'Full Upper-Limb Active Kinetic Range',
  };

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLAYING':
        return const Color(0xFF059669);
      case 'START_TRIGGERED':
        return const Color(0xFFD97706);
      case 'COMPLETED':
        return const Color(0xFF0284C7);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: 'VR Protocol Level Prescription',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Active Prescription:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      'Level $currentLevel',
                      style: const TextStyle(
                        color: Color(0xFF0D47A1),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _statusColor(gameStatus),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    gameStatus,
                    style: TextStyle(
                      color: _statusColor(gameStatus),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _levelDescriptions[currentLevel] ?? 'Clinical Exercise Protocol',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Prescribe Target Level for Patient:',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 3, 4, 5].map((lvl) {
              final isSelected = lvl == currentLevel;
              return ChoiceChip(
                label: Text('Level $lvl'),
                selected: isSelected,
                selectedColor: const Color(0xFF0D47A1),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? const Color(0xFF0D47A1) : const Color(0xFFCBD5E1),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                onSelected: isUpdating ? null : (_) => onLevelSelected(lvl),
              );
            }).toList(),
          ),
          if (isUpdating) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D47A1)),
                ),
                SizedBox(width: 8),
                Text('Transmitting prescription to patient device...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ClinicalStatusPill extends StatelessWidget {
  const _ClinicalStatusPill({required this.label});

  final String label;

  Color _color() {
    final lower = label.toLowerCase();
    if (lower.contains('improved')) return const Color(0xFF059669);
    if (lower.contains('improving')) return const Color(0xFFD97706);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}
