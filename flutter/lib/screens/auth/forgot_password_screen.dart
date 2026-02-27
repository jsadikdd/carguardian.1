import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            Text(
              _sent
                  ? 'Reset email sent! Check your inbox.'
                  : 'Enter your email to receive a password reset link.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (!_sent) ...[
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final ok = await context
                      .read<AuthProvider>()
                      .resetPassword(_emailCtrl.text.trim());
                  if (ok) setState(() => _sent = true);
                },
                child: const Text('Send Reset Link'),
              ),
            ] else
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
          ],
        ),
      ),
    );
  }
}
