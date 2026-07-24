import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/core/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('saved_login_id');
    final savedPassword = prefs.getString('saved_password');
    if (savedId != null && savedPassword != null) {
      setState(() {
        _loginIdController.text = savedId;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  void _login() async {
    if (_loginIdController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.orange),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).login(
      _loginIdController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!success && mounted) {
      final error = ref.read(authProvider).error;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Login Failed', style: TextStyle(color: Colors.red)),
          content: Text(error ?? 'Invalid credentials'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (success) {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_login_id', _loginIdController.text.trim());
        await prefs.setString('saved_password', _passwordController.text.trim());
      } else {
        await prefs.remove('saved_login_id');
        await prefs.remove('saved_password');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop',
            fit: BoxFit.cover,
          ),
          // Dark Overlay
          Container(color: Colors.black.withOpacity(0.5)),
          // Login Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.dumbbell, size: 48, color: Color(0xFF6C5CE7)),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Member Login',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Welcome back to your gym app',
                            style: TextStyle(color: Colors.white.withOpacity(0.8)),
                          ),
                          const SizedBox(height: 48),
                          TextField(
                            controller: _loginIdController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email or Phone Number',
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              prefixIcon: Icon(LucideIcons.user, color: Colors.white.withOpacity(0.7)),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              prefixIcon: Icon(LucideIcons.lock, color: Colors.white.withOpacity(0.7)),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff, color: Colors.white.withOpacity(0.7)),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Theme(
                                data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: Colors.white.withOpacity(0.7),
                                ),
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFF6C5CE7),
                                  checkColor: Colors.white,
                                ),
                              ),
                              Text(
                                'Remember Me',
                                style: TextStyle(color: Colors.white.withOpacity(0.8)),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => context.push('/forgot-password'),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C5CE7),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.white.withOpacity(0.8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
