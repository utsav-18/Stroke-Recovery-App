import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _doctor;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isEditing = false;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final doctor = await ApiService().getDoctorMe();
      if (mounted) {
        setState(() {
          _doctor = doctor;
          _isLoading = false;
        });
        _populateControllers();
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

  void _populateControllers() {
    if (_doctor != null) {
      _nameController.text = _doctor!['name'] as String? ?? '';
      _specializationController.text = _doctor!['specialization'] as String? ?? '';
      _phoneController.text = _doctor!['phone'] as String? ?? '';
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _populateControllers();
      }
    });
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Physician name cannot be blank')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await ApiService().updateDoctorMe(
        name: name,
        specialization: _specializationController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _doctor = updated;
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clinician profile updated successfully'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile update error: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
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
          'Physician Credentials & Profile',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        actions: [
          if (_doctor != null && !_isEditing && !_isSaving)
            IconButton(
              onPressed: _toggleEdit,
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF0D47A1)),
              tooltip: 'Edit Profile',
            ),
          if (_isEditing && !_isSaving)
            IconButton(
              onPressed: _toggleEdit,
              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              tooltip: 'Cancel',
            ),
          if (_isEditing && !_isSaving)
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check_rounded, color: Color(0xFF059669)),
              tooltip: 'Save Profile',
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D47A1)),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626))))
              : _doctor == null
                  ? const Center(child: Text('No clinician record found.'))
                  : SingleChildScrollView(
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
                                  child: const Icon(Icons.medical_services_outlined, size: 34, color: Color(0xFF0D47A1)),
                                ),
                                const SizedBox(height: 14),
                                if (!_isEditing) ...[
                                  Text(
                                    _doctor!['name'] as String,
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
                                      'Staff ID: ${_doctor!['doctor_code']}',
                                      style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ] else ...[
                                  TextFormField(
                                    controller: _nameController,
                                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700),
                                    decoration: const InputDecoration(
                                      labelText: 'Physician Full Name',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!_isEditing) ...[
                            _InfoTile(label: 'Medical Specialization', value: _doctor!['specialization'] as String? ?? 'Physical Medicine & Rehabilitation'),
                            _InfoTile(label: 'Institutional Phone', value: _doctor!['phone'] as String? ?? 'Not specified'),
                          ] else ...[
                            TextFormField(
                              controller: _specializationController,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'Medical Specialization',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'Institutional Phone',
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                          const SizedBox(height: 32),
                          if (!_isEditing)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFECACA)),
                                foregroundColor: const Color(0xFFDC2626),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _logout,
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: const Text('Sign Out of Clinical Console'),
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
