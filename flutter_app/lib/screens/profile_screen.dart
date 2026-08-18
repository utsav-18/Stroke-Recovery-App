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
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: dobController, decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)')),
                const SizedBox(height: 8),
                TextField(controller: genderController, decoration: const InputDecoration(labelText: 'Gender')),
                const SizedBox(height: 8),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
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
              child: const Text('Save'),
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
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _isLoading || _patient == null ? null : _editProfile,
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
              : _patient == null
                  ? const Center(child: Text('No profile data.'))
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111C2E),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFF24314A)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2F80FF).withValues(alpha: 0.18),
                                  ),
                                  child: const Icon(Icons.person_rounded, size: 36, color: Color(0xFF61E4C5)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _patient!.name,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _patient!.patientCode,
                                  style: const TextStyle(color: Color(0xFF9FB1CA)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _InfoTile(label: 'Date of birth', value: _patient!.dateOfBirth.isEmpty ? 'Not set' : _patient!.dateOfBirth),
                          _InfoTile(label: 'Gender', value: _patient!.gender.isEmpty ? 'Not set' : _patient!.gender),
                          _InfoTile(label: 'Phone', value: _patient!.phone.isEmpty ? 'Not set' : _patient!.phone),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Logout'),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF24314A)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9FB1CA))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
