import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Patient? _patient;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final patient = await ApiService().getPatientMe();
      if (mounted) {
        setState(() {
          _patient = patient;
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

  Future<void> _editProfile() async {
    if (_patient == null) return;
    
    final nameController = TextEditingController(text: _patient!.name);
    final dobController = TextEditingController(text: _patient!.dateOfBirth);
    final genderController = TextEditingController(text: _patient!.gender);
    final phoneController = TextEditingController(text: _patient!.phone);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: const Text('Edit Patient Demographics', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Patient Legal Name')),
                const SizedBox(height: 10),
                TextField(controller: dobController, decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)')),
                const SizedBox(height: 10),
                TextField(controller: genderController, decoration: const InputDecoration(labelText: 'Biological Gender')),
                const SizedBox(height: 10),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Contact Phone Number')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save Record'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        final updated = await ApiService().updatePatientMe(
          name: nameController.text,
          dateOfBirth: dobController.text,
          gender: genderController.text,
          phone: phoneController.text,
        );
        if (mounted) {
          setState(() {
            _patient = updated;
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
  }

  Future<void> _logout() async {
    await ApiService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Patient Clinical Record',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading || _patient == null ? null : _editProfile,
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF0D47A1)),
            tooltip: 'Edit Record',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626))))
              : _patient == null
                  ? const Center(child: Text('No patient record found.'))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
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
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
                                  ),
                                  child: const Icon(Icons.person_rounded, size: 34, color: Color(0xFF0D47A1)),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _patient!.name,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Medical Record Number: ${_patient!.patientCode}',
                                    style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoTile(label: 'Date of Birth', value: _patient!.dateOfBirth.isEmpty ? 'Unspecified' : _patient!.dateOfBirth),
                          _InfoTile(label: 'Biological Gender', value: _patient!.gender.isEmpty ? 'Unspecified' : _patient!.gender),
                          _InfoTile(label: 'Primary Phone', value: _patient!.phone.isEmpty ? 'Unspecified' : _patient!.phone),
                          const Spacer(),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              foregroundColor: const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Sign Out of Patient Portal'),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 13)),
        ],
      ),
    );
  }
}
