import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../core/constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'owner@stockvision.demo');
  final _passwordController = TextEditingController(text: 'demo123');
  bool _obscure = true;

  static const _demoAccounts = [
    {'label': 'Owner', 'email': 'owner@stockvision.demo'},
    {'label': 'General Manager', 'email': 'manager@stockvision.demo'},
    {'label': 'Branch Manager', 'email': 'branch@stockvision.demo'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.insights_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              Text(AppConstants.appName, style: GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(AppConstants.tagline, style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
              const SizedBox(height: 36),

              Text('Email', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'you@company.com', prefixIcon: Icon(Icons.mail_outline_rounded)),
              ),
              const SizedBox(height: 18),
              Text('Password', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              if (authState.error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.critical.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.critical, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(authState.error!, style: const TextStyle(color: AppColors.critical, fontSize: 13))),
                  ]),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.loading
                      ? null
                      : () => ref.read(authProvider.notifier).login(_emailController.text.trim(), _passwordController.text),
                  child: authState.loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Sign In'),
                ),
              ),

              const SizedBox(height: 32),
              Text('Quick demo login', style: theme.textTheme.bodySmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _demoAccounts.map((acc) {
                  return OutlinedButton(
                    onPressed: () {
                      _emailController.text = acc['email']!;
                      _passwordController.text = 'demo123';
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(acc['label']!, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text('Password for all demo accounts: demo123', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
