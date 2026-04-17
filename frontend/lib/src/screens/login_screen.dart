import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../auth/auth_repository.dart';
import '../debug/debug_log.dart';
import '../debug/debug_log_screen.dart';
import '../models/fitnet_user.dart';
import '../widgets/login_three_style_background.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authRepository,
    required this.onLoggedIn,
  });

  final AuthRepository authRepository;
  final ValueChanged<FitnetUser> onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    DebugLog.add('ui', 'login: pressed', details: {'email': _email.text.trim()});
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await widget.authRepository.login(email: _email.text.trim(), password: _password.text);
      final user = await widget.authRepository.me();
      widget.onLoggedIn(user);
    } on ApiException catch (e) {
      DebugLog.add('error', 'login ApiException: ${e.statusCode} ${e.message}', details: e.body);
      setState(() => _error = e.message);
    } catch (e, st) {
      DebugLog.add('error', 'login exception: $e', details: st);
      setState(() => _error = 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: LoginThreeStyleBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _GlassLoginCard(
                  theme: theme,
                  error: _error,
                  formKey: _formKey,
                  email: _email,
                  password: _password,
                  loading: _loading,
                  onSubmit: _submit,
                  authRepository: widget.authRepository,
                  onRegistered: widget.onLoggedIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassLoginCard extends StatelessWidget {
  const _GlassLoginCard({
    required this.theme,
    required this.error,
    required this.formKey,
    required this.email,
    required this.password,
    required this.loading,
    required this.onSubmit,
    required this.authRepository,
    required this.onRegistered,
  });

  final ThemeData theme;
  final String? error;
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool loading;
  final VoidCallback onSubmit;
  final AuthRepository authRepository;
  final ValueChanged<FitnetUser> onRegistered;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
            blurRadius: 32,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0EA5E9).withValues(alpha: 0.9),
                        const Color(0xFF6366F1).withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fitnet',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Đăng nhập để vào bảng tin & quản trị',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugLogScreen()));
                },
                icon: const Icon(Icons.bug_report_outlined, size: 18),
                label: const Text('Debug logs'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
              ),
            ),
            if (error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
              ),
              const SizedBox(height: 12),
            ],
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Tài khoản (email hoặc username)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Nhập email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
                    onFieldSubmitted: (_) => onSubmit(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: loading ? null : onSubmit,
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterScreen(
                            authRepository: authRepository,
                            onRegistered: onRegistered,
                          ),
                        ),
                      );
                    },
                    child: const Text('Chưa có tài khoản? Đăng ký'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mặc định (seed): admin / admin123',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF94A3B8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
