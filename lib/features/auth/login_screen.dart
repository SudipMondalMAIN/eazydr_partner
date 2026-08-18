import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/routing/route_names.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final identifier = _identifierCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (identifier.length < 3 || password.isEmpty) {
      setState(() => _error = 'Enter your phone/email and password');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).loginWithPassword(
          identifier: identifier, password: password);
      final auth = ref.read(authProvider);
      if (!mounted) return;
      if (auth.status == SessionStatus.loggedIn) {
        context.go(Routes.home);
      } else {
        setState(() => _error = auth.error ?? 'This app is for partner accounts only.');
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Center(
                child: BrandHeader(
                    logoSize: 88, tagline: 'Manage bookings, grow your practice'),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(kRadiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Partner login',
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('Sign in with your registered phone or email',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Text('Phone or Email', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _identifierCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          hintText: '98765 43210 or you@example.com'),
                    ),
                    const SizedBox(height: 16),
                    Text('Password', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        hintText: 'Your password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen())),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      Text(_error!,
                          style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Sign in'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'By continuing you agree to EazyDoctor\'s partner terms.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: const Text("Don't have a partner account? Sign up"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
