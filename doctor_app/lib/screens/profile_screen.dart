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
        _populateControllers(); // Reset on cancel
      }
    });
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
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
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
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
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_doctor != null && !_isEditing && !_isSaving)
            IconButton(
              onPressed: _toggleEdit,
              icon: const Icon(Icons.edit_rounded),
            ),
          if (_isEditing && !_isSaving)
            IconButton(
              onPressed: _toggleEdit,
              icon: const Icon(Icons.close_rounded),
            ),
          if (_isEditing && !_isSaving)
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check_rounded, color: Color(0xFF61E4C5)),
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
              : _doctor == null
                  ? const Center(child: Text('No profile data.'))
                  : SingleChildScrollView(
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
                                if (!_isEditing) ...[
                                  Text(
                                    _doctor!['name'] as String,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _doctor!['doctor_code'] as String,
                                    style: const TextStyle(color: Color(0xFF9FB1CA)),
                                  ),
                                ] else ...[
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                      filled: true,
                                      fillColor: Color(0xFF0B1221),
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!_isEditing) ...[
                            _InfoTile(label: 'Specialization', value: _doctor!['specialization'] as String? ?? 'Not set'),
                            _InfoTile(label: 'Phone', value: _doctor!['phone'] as String? ?? 'Not set'),
                          ] else ...[
                            TextFormField(
                              controller: _specializationController,
                              decoration: const InputDecoration(
                                labelText: 'Specialization',
                                filled: true,
                                fillColor: Color(0xFF111C2E),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                filled: true,
                                fillColor: Color(0xFF111C2E),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                          const SizedBox(height: 40),
                          if (!_isEditing)
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
