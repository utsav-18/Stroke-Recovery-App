import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'patient_progress_screen.dart'; // We will pass patientId to this
import 'profile_screen.dart'; // We'll modify this to be DoctorProfileScreen or just ProfileScreen for doctor

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  Map<String, dynamic>? _doctor;
  List<Map<String, dynamic>> _patients = [];
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
      final doctor = await api.getDoctorMe();
      final patients = await api.getAssignedPatients();
      
      if (mounted) {
        setState(() {
          _doctor = doctor;
          _patients = patients;
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

    if (_errorMessage != null || _doctor == null) {
      return Scaffold(
        body: Center(
          child: Text('Error loading dashboard: $_errorMessage', style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('RehabTrack Doctor'),
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
                name: _doctor!['name'],
                progressLabel: '${_patients.length} patients assigned',
              ),
              const SizedBox(height: 24),
              const Text(
                'Assigned Patients',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (_patients.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No assigned patients.', style: TextStyle(color: Color(0xFF9FB1CA))),
                  ),
                )
              else
                ..._patients.map((p) => _PatientCard(patient: p)),
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
            child: const Icon(Icons.medical_services_rounded, color: Color(0xFF61E4C5)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $name',
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

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});

  final Map<String, dynamic> patient;

  @override
  Widget build(BuildContext context) {
    final status = patient['latest_movement_status'] as String?;
    final displayStatus = status ?? 'No analysis yet';
    final confidence = patient['latest_confidence'] as double?;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PatientProgressScreen(patientId: patient['id'] as int),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    patient['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                _Badge(label: displayStatus, color: _movementColor(displayStatus)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Code: ${patient['patient_code']}',
              style: const TextStyle(color: Color(0xFF9FB1CA), fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.date_range_rounded, size: 16, color: Color(0xFF61E4C5)),
                const SizedBox(width: 6),
                Text(
                  patient['latest_session_date'] != null 
                    ? patient['latest_session_date'].toString().split('T').first 
                    : 'No sessions',
                  style: const TextStyle(color: Color(0xFFB7C8D9), fontSize: 13),
                ),
                const Spacer(),
                if (confidence != null)
                  Text(
                    '${(confidence * 100).toStringAsFixed(0)}% avg conf',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
              ],
            ),
          ],
        ),
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
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
