import 'package:superadmin_web/core/config/env.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int _currentImageIndex = 0;
  Timer? _timer;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _is2FAStep = false;
  String? _userIdFor2FA;
  bool _isFallbackMode = false;
  String? _2faMethod;

  final List<String> _backgroundImages = [
    'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?q=80&w=2070&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=2070&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=2070&auto=format&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _backgroundImages.length;
      });
    });
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    final savedPassword = prefs.getString('remembered_password');
    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['requires2FA'] == true) {
          setState(() {
            _is2FAStep = true;
            _userIdFor2FA = data['userId'];
            _2faMethod = data['method'];
            _errorMessage = 'Please check your app or email for the OTP.';
          });
          return;
        }

        // Verify user is superadmin
        if (data['role'] == 'superadmin') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          if (_rememberMe) {
            await prefs.setString('remembered_email', _emailController.text);
            await prefs.setString('remembered_password', _passwordController.text);
          } else {
            await prefs.remove('remembered_email');
            await prefs.remove('remembered_password');
          }
          
          if (mounted) {
            context.go('/dashboard');
          }
        } else {
          setState(() {
            _errorMessage = 'Unauthorized: Only superadmins can access this panel.';
          });
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data['message'] ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      print('Login Error: $e');
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestFallbackOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/auth/send-fallback-2fa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _userIdFor2FA}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _isFallbackMode = true;
          _errorMessage = 'An OTP has been sent to your email.';
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() => _errorMessage = data['message'] ?? 'Failed to send OTP.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verify2FA() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/auth/verify-2fa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userIdFor2FA,
          'code': _otpController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['role'] == 'superadmin') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          if (_rememberMe) {
            await prefs.setString('remembered_email', _emailController.text);
            await prefs.setString('remembered_password', _passwordController.text);
          }
          if (mounted) context.go('/dashboard');
        } else {
          setState(() => _errorMessage = 'Unauthorized: Only superadmins can access this panel.');
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() => _errorMessage = data['message'] ?? 'Invalid code.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          // Left Side - Branding with Image Carousel
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Carousel
                AnimatedSwitcher(
                  duration: const Duration(seconds: 1),
                  child: Container(
                    key: ValueKey<int>(_currentImageIndex),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(_backgroundImages[_currentImageIndex]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Deep dark overlay for text readability (Neutral Charcoal)
                Container(
                  color: const Color(0xFF111827).withOpacity(0.85),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.dumbbell, color: Theme.of(context).colorScheme.surface, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'GymSaaS Pro',
                            style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'The most powerful gym\nmanagement platform,\nbuilt for scale.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Streamline operations, maximize retention, and scale your fitness enterprise with unparalleled administrative control.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '© 2024 GymSaaS Inc.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Right Side - Login Form
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: ((scale - 0.8) / 0.2).clamp(0.0, 1.0), // Fade in alongside scale
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 440,
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.12), // Subtle emerald glow
                          blurRadius: 50,
                          spreadRadius: 15,
                          offset: const Offset(0, 15),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome back, Admin',
                          style: TextStyle(
                            color: const Color(0xFF111827),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please enter your credentials to access the Super Admin panel.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.alertCircle, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                              ],
                            ),
                          ),
                        
                        if (_is2FAStep) ...[
                          Text(_isFallbackMode ? 'Enter Email OTP Code' : 'Enter Authenticator App Code', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _otpController,
                            decoration: InputDecoration(
                              hintText: '123456',
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
                              prefixIcon: const Icon(LucideIcons.shield, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.02),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => setState(() {
                                  _is2FAStep = false;
                                  _isFallbackMode = false;
                                  _errorMessage = null;
                                  _otpController.clear();
                                }),
                                child: const Text('Back to Login', style: TextStyle(color: Color(0xFF10B981))),
                              ),
                              if (!_isFallbackMode && _2faMethod == 'app')
                                TextButton(
                                  onPressed: _requestFallbackOTP,
                                  child: const Text('Try another way', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ] else ...[
                        const Text('Email address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'admin@gymsaas.pro',
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14),
                            prefixIcon: const Icon(LucideIcons.mail, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.02),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14),
                            prefixIcon: const Icon(LucideIcons.lock, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.02),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rememberMe = !_rememberMe;
                                });
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _rememberMe ? const Color(0xFF10B981) : Colors.transparent,
                                      border: Border.all(color: _rememberMe ? const Color(0xFF10B981) : Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: _rememberMe ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Remember me', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ],
                        
                        const SizedBox(height: 40),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : (_is2FAStep ? _verify2FA : _login),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_is2FAStep ? 'Verify' : 'Sign In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      const Icon(LucideIcons.arrowRight, size: 20),
                                    ],
                                  ),
                          ),
                        ),
                      ],
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
