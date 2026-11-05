import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'patient_progress_screen.dart';
import 'profile_screen.dart';

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
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0D47A1)),
              SizedBox(height: 14),
              Text(
                'Loading Patient Cohort...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _doctor == null) {
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
                  'Error loading clinician dashboard: $_errorMessage',
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Physician Oversight Console',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Department of Physical Medicine & Rehabilitation',
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
            tooltip: 'Clinician Profile',
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
                name: _doctor!['name'],
                specialization: _doctor!['specialization'] ?? 'Neurology & Physical Medicine',
                progressLabel: '${_patients.length} assigned patient cohorts',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Rehabilitation Patients',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      '${_patients.length} Enrolled',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_patients.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline_rounded, color: Color(0xFF94A3B8), size: 36),
                        SizedBox(height: 10),
                        Text(
                          'No patients currently assigned to your roster.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
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
  const _WelcomeCard({
    required this.name,
    required this.specialization,
    required this.progressLabel,
  });

  final String name;
  final String specialization;
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.medical_services_outlined, color: Color(0xFF0D47A1), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.startsWith('Dr.') ? name : 'Dr. $name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  specialization,
                  style: const TextStyle(color: Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  progressLabel,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
    final displayStatus = status ?? 'Baseline Pending';
    final confidence = patient['latest_confidence'] as double?;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.person_outline, size: 16, color: Color(0xFF0D47A1)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          patient['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _ClinicalStatusBadge(label: displayStatus, color: _movementColor(displayStatus)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Text(
                    'MRN: ${patient['patient_code']}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF475569)),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 5),
                  Text(
                    patient['latest_session_date'] != null 
                      ? patient['latest_session_date'].toString().split('T').first 
                      : 'No records',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (confidence != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.insights_rounded, size: 14, color: Color(0xFF059669)),
                  const SizedBox(width: 6),
                  Text(
                    'Kinematic Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF059669)),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _movementColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('improved')) return const Color(0xFF059669);
    if (normalized.contains('improving')) return const Color(0xFFD97706);
    return const Color(0xFF64748B);
  }
}

class _ClinicalStatusBadge extends StatelessWidget {
  const _ClinicalStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
