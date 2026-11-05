import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_service.dart';
import 'patient_home_screen.dart';
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
      return 'Email is required';
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(text)) {
      return 'Enter a valid email address';
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
        MaterialPageRoute<void>(builder: (_) => const PatientHomeScreen()),
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
    bool isChecking = false;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.dns_outlined, color: Color(0xFF67B7F7)),
                  SizedBox(width: 8),
                  Text('Server Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Backend API URL for mobile app connection:',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'API Base URL',
                        hintText: 'https://...',
                        border: OutlineInputBorder(),
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
                          onPressed: () {
                            setDialogState(() {
                              controller.text = AppConfig.defaultCloudUrl;
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('Local Wi-Fi', style: TextStyle(fontSize: 11)),
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
                      Text(
                        statusMsg!,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusMsg!.contains('✓') ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: isChecking
                          ? null
                          : () async {
                              setDialogState(() {
                                isChecking = true;
                                statusMsg = 'Testing connection...';
                              });
                              final ok = await ApiService().testConnection(controller.text);
                              setDialogState(() {
                                isChecking = false;
                                statusMsg = ok ? '✓ Connected to backend!' : '✗ Could not connect';
                              });
                            },
                      icon: isChecking
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.wifi_tethering, size: 16),
                      label: const Text('Test Connection'),
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
                      SnackBar(content: Text('Server URL set to: ${ApiService().currentBaseUrl}')),
                    );
                  },
                  child: const Text('Save'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Server Settings',
            onPressed: _showServerSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset('assets/images/app_logo.png', height: 80),
                        const SizedBox(height: 16),
                        const Text(
                          'RehabTrack',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to review exercise recordings and recovery analysis.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFB8C7D9)),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: InkWell(
                            onTap: _showServerSettingsDialog,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0x10FFFFFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cloud_done_outlined, size: 14, color: Color(0xFF67B7F7)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      ApiService().currentBaseUrl,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF67B7F7)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_outlined, size: 12, color: Colors.grey),
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
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          validator: _validatePassword,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                        ],
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _submitLogin,
                          icon: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.login_rounded),
                          label: Text(_isLoading ? 'Logging in...' : 'Login'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
                            );
                          },
                          child: const Text('Don\'t have an account? Signup'),
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
