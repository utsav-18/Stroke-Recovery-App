import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_service.dart';
import 'doctor_home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Staff email is required';
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(text)) {
      return 'Please enter a valid hospital email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Password is required';
    }
    if ((value ?? '').trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService().login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const DoctorHomeScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showServerSettingsDialog() {
    final controller = TextEditingController(text: ApiService().currentBaseUrl);
    String? statusMsg;
    bool? isSuccess;
    bool isChecking = false;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.dns_outlined, color: Color(0xFF0D47A1), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Clinical Server Settings',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Target API endpoint for clinical rehabilitation systems:',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        labelText: 'Endpoint URL',
                        hintText: 'https://...',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          label: const Text('Render Cloud', style: TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          onPressed: () {
                            setDialogState(() {
                              controller.text = AppConfig.defaultCloudUrl;
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('Hospital Wi-Fi', style: TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          onPressed: () {
                            setDialogState(() {
                              controller.text = AppConfig.defaultLocalUrl;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (statusMsg != null)
                      Row(
                        children: [
                          Icon(
                            isSuccess == true ? Icons.check_circle_outline : Icons.error_outline,
                            size: 16,
                            color: isSuccess == true ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              statusMsg!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSuccess == true ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isChecking
                          ? null
                          : () async {
                              setDialogState(() {
                                isChecking = true;
                                statusMsg = 'Testing connection...';
                                isSuccess = null;
                              });
                              final ok = await ApiService().testConnection(controller.text);
                              setDialogState(() {
                                isChecking = false;
                                isSuccess = ok;
                                statusMsg = ok ? 'Connection established (HTTP 200)' : 'Unable to connect to host';
                              });
                            },
                      icon: isChecking
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.wifi_tethering, size: 16),
                      label: const Text('Verify Connection'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    ApiService().setBaseUrl(controller.text);
                    Navigator.of(ctx).pop();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Endpoint configured: ${ApiService().currentBaseUrl}')),
                    );
                  },
                  child: const Text('Apply Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF0D47A1), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'RehabTrack Clinical',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF475569)),
            tooltip: 'Server Settings',
            onPressed: _showServerSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                color: Colors.white,
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D47A1).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.medical_services_outlined,
                              size: 34,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Clinician Portal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Physician & Therapist Authentication',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: InkWell(
                            onTap: _showServerSettingsDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cloud_done_outlined, size: 14, color: Color(0xFF0D47A1)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      ApiService().currentBaseUrl,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0D47A1),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_outlined, size: 12, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: 'Staff Email',
                            hintText: 'dr.smith@hospital.org',
                            prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          validator: _validatePassword,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: 'Staff Password',
                            prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _submitLogin,
                          icon: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.lock_open_rounded, size: 18),
                          label: Text(_isLoading ? 'Authenticating...' : 'Sign In to Clinical Portal'),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
                            );
                          },
                          child: const Text('Register Clinician Credentials'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
