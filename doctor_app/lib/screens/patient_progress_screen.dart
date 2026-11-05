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
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingLevel = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update level: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
                        _LevelAssignmentCard(
                          currentLevel: _currentLevel ?? _progress!.assignedLevel,
                          gameStatus: _progress!.gameStatus,
                          isUpdating: _isUpdatingLevel,
                          onLevelSelected: _updateLevel,
                        ),
                        const SizedBox(height: 16),
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
    1: 'Mild Range of Motion',
    2: 'Arm Elevation & Reach',
    3: 'Target Coordination',
    4: 'Speed & Resistance',
    5: 'Full Upper-Limb Extension',
  };

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLAYING':
        return const Color(0xFF10B981); // green
      case 'START_TRIGGERED':
        return const Color(0xFFF59E0B); // amber
      case 'COMPLETED':
        return const Color(0xFF3B82F6); // blue
      default:
        return const Color(0xFF9CA3AF); // gray
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      title: 'VR Rehab Prescription',
      icon: Icons.videogame_asset_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Active:', style: TextStyle(color: Color(0xFFB7C8D9), fontSize: 13)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F80FF).withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2F80FF)),
                    ),
                    child: Text(
                      'Level $currentLevel',
                      style: const TextStyle(
                        color: Color(0xFF2F80FF),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _statusColor(gameStatus),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    gameStatus,
                    style: TextStyle(
                      color: _statusColor(gameStatus),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _levelDescriptions[currentLevel] ?? 'Custom Exercise Level',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFE2E8F0),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Level to Prescribe:',
            style: TextStyle(color: Color(0xFF96A9C2), fontSize: 12, fontWeight: FontWeight.w500),
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
                selectedColor: const Color(0xFF2F80FF),
                backgroundColor: const Color(0xFF131D2D),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Updating prescription...', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

