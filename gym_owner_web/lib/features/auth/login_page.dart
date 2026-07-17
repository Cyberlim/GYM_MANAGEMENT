import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_web/core/providers/app_settings_provider.dart';
import 'package:gym_owner_web/data/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_owner_web/core/providers/user_provider.dart';
import 'package:gym_owner_web/features/onboarding/google_btn.dart';
import 'package:pinput/pinput.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  int _currentImageIndex = 0;
  Timer? _timer;

  final _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _twoFactorController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _show2FA = false;
  String? _2faUserId;
  String? _2faMethod;
  bool _obscurePassword = true;

  final List<String> _backgroundImages = [
    'https://images.unsplash.com/photo-1576678927484-cc907957088c?q=80&w=2187&auto=format&fit=crop', // Different gym image 1
    'https://images.unsplash.com/photo-1593079831268-3381b0c4239a?q=80&w=2069&auto=format&fit=crop', // Different gym image 2
    'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=2070&auto=format&fit=crop', // Different gym image 3
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _backgroundImages.length;
      });
    });

    try {
      GoogleSignIn.instance.initialize(
        clientId: '123767483603-urperi4kp0v46u5c5ihe97s078rh76mu.apps.googleusercontent.com',
      );
    } catch (_) {}

    try {
      GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _handleGoogleAccount(event.user);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _twoFactorController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final response = await api.post('/auth/login', {
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      if (response != null) {
        if (response['requiresEmailVerification'] == true) {
          if (mounted) {
            context.go('/verify-email/${response['userId']}');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Please verify your email address.'), backgroundColor: Colors.red));
          }
          return;
        }

        if (response['requires2FA'] == true) {
          if (mounted) {
            setState(() {
              _show2FA = true;
              _2faUserId = response['userId'];
              _2faMethod = response['method'];
            });
          }
          return;
        }

        if (response['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', response['token']);
          
          ref.read(userProvider.notifier).refresh();

          if (mounted) {
            context.go('/dashboard');
          }
        }
      }
    } on SuspensionException catch (e) {
      if (mounted) {
        context.go('/suspended/${e.suspensionId}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          String err = e.toString();
          if (err.contains('"message":"')) {
            final match = RegExp(r'"message":"(.*?)"').firstMatch(err);
            if (match != null) err = match.group(1) ?? err;
          }
          _errorMessage = err.replaceAll('Exception: API Error: 401 - ', '').replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted && !_show2FA) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verify2FA() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final response = await api.post('/auth/verify-2fa', {
        'userId': _2faUserId,
        'code': _twoFactorController.text,
      });

      if (response != null && response['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        
        ref.read(userProvider.notifier).refresh();

        if (mounted) {
          context.go('/dashboard');
        }
      }
    } on SuspensionException catch (e) {
      if (mounted) {
        context.go('/suspended/${e.suspensionId}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          String err = e.toString();
          if (err.contains('"message":"')) {
            final match = RegExp(r'"message":"(.*?)"').firstMatch(err);
            if (match != null) err = match.group(1) ?? err;
          }
          _errorMessage = err.replaceAll('Exception: API Error: 400 - ', '').replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleAccount(GoogleSignInAccount account) async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAuthentication auth = await account.authentication;
      if (auth.idToken == null) {
        throw Exception('Google Sign-In failed: No ID Token returned');
      }
      
      final url = Uri.parse('http://localhost:5000/api/auth/google-login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': account.displayName,
          'email': account.email,
          'profileImage': account.photoUrl,
          'googleId': account.id,
          'idToken': auth.idToken,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        
        ref.read(userProvider.notifier).refresh();

        if (mounted) {
          if (data['isNewUser'] == true) {
            context.go('/gym-setup');
          } else {
            context.go('/dashboard');
          }
        }
      } else {
        final data = jsonDecode(response.body);
        if (response.statusCode == 403 && data['isSuspended'] == true) {
          if (mounted) {
            context.go('/suspended/${data['suspensionId']}');
          }
          return;
        }
        throw Exception(data['message'] ?? 'Failed to authenticate');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      
      try {
        await googleSignIn.initialize(
          clientId: '123767483603-urperi4kp0v46u5c5ihe97s078rh76mu.apps.googleusercontent.com',
        );
      } catch (e) {
        // Already initialized
      }

      final GoogleSignInAccount? account = await googleSignIn.authenticate();
      if (account != null) {
        await _handleGoogleAccount(account);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appName = ref.watch(appNameProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Side - Branding (Visible only on larger screens)
          Expanded(
            flex: 5,
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
                // Dark overlay for text readability
                Container(
                  color: Colors.black.withOpacity(0.75),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCFFF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.dumbbell, color: Color(0xFFCFFF50), size: 32),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'GYM MANAGEMENT',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Marketing Text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Elevate your\ngym management\nexperience.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Streamline operations, boost member engagement, and grow your revenue with $appName\'s all-in-one platform.',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),

                      // Decorative Elements / Social Proof
                      Row(
                        children: [
                          _buildAvatarGroup(),
                          const SizedBox(width: 16),
                          const Text(
                            'Trusted by 2,000+ gym owners',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Right Side - Login Form
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please enter your details to sign in.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Email Field
                      Text(
                        _show2FA 
                          ? 'Enter 2FA Code'
                          : 'Email',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (_show2FA) ...[
                        Pinput(
                          length: 6,
                          controller: _twoFactorController,
                          defaultPinTheme: PinTheme(
                            width: 56,
                            height: 64,
                            textStyle: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                          ),
                          focusedPinTheme: PinTheme(
                            width: 56,
                            height: 64,
                            textStyle: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                          ),
                          hapticFeedbackType: HapticFeedbackType.lightImpact,
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      if (!_show2FA) ...[
                        // Password Field
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black, width: 2),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, color: Colors.grey.shade400, size: 20),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Remember & Forgot
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: true,
                                    onChanged: (val) {},
                                    activeColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Remember for 30 days', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      
                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_show2FA ? _verify2FA : _login),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCFFF50), // Neon primary
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading 
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : Text(
                                _show2FA ? 'Verify 2FA' : 'Sign In',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.withOpacity(0.2))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: TextStyle(color: Colors.black54, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.withOpacity(0.2))),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Google Sign In Button
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: buildGoogleSignInButton(
                          onPressed: _isLoading ? () {} : _googleSignIn,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Sign Up Prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Don\'t have an account? ', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                          TextButton(
                            onPressed: () => context.go('/signup'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Sign up', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGroup() {
    return SizedBox(
      width: 100,
      height: 40,
      child: Stack(
        children: [
          Positioned(left: 0, child: _avatar('https://i.pravatar.cc/150?img=11')),
          Positioned(left: 20, child: _avatar('https://i.pravatar.cc/150?img=12')),
          Positioned(left: 40, child: _avatar('https://i.pravatar.cc/150?img=13')),
          Positioned(left: 60, child: _avatar('https://i.pravatar.cc/150?img=14')),
        ],
      ),
    );
  }

  Widget _avatar(String url) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF161616), width: 2),
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(url),
      ),
    );
  }
}
