import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/core/providers/app_settings_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'google_btn.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    try {
      GoogleSignIn.instance.initialize(
        clientId: '123767483603-urperi4kp0v46u5c5ihe97s078rh76mu.apps.googleusercontent.com',
      );
    } catch (_) {}

    GoogleSignIn.instance.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        _handleGoogleAccount(event.user);
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
    }
  }

  Future<void> _signup() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      var uri = Uri.parse('http://localhost:5000/api/auth/signup');
      var request = http.MultipartRequest('POST', uri);

      request.fields['name'] = _nameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['password'] = _passwordController.text;

      if (_profileImage != null) {
        var bytes = await _profileImage!.readAsBytes();
        var multipartFile = http.MultipartFile.fromBytes(
          'profileImage',
          bytes,
          filename: _profileImage!.name,
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (response.statusCode == 201) {
        if (data['requiresEmailVerification'] == true) {
          if (mounted) context.go('/verify-email/${data['userId']}');
        } else {
          // Save token (You'd typically use SharedPreferences or Riverpod here)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          
          if (mounted) context.go('/gym-setup');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Signup failed'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        
        if (mounted) {
          if (data['isNewUser'] == true) {
            context.go('/gym-setup');
          } else {
            context.go('/dashboard');
          }
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to authenticate');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
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
      
      // Initialize (safe to call multiple times if we catch StateError, but usually fine)
      try {
        await googleSignIn.initialize(
          clientId: '123767483603-urperi4kp0v46u5c5ihe97s078rh76mu.apps.googleusercontent.com',
        );
      } catch (_) {}
      
      final GoogleSignInAccount? account = await googleSignIn.authenticate();
      
      if (account != null) {
        await _handleGoogleAccount(account);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appName = ref.watch(appNameProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Image Picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF), // Light indigo
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5), width: 2),
                      ),
                      child: _profileImage != null
                          ? FutureBuilder<Widget>(
                              future: _profileImage!.readAsBytes().then((bytes) => ClipOval(
                                child: Image.memory(bytes, fit: BoxFit.cover, width: 80, height: 80),
                              )),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) return snapshot.data!;
                                return const CircularProgressIndicator(color: Color(0xFF6366F1));
                              },
                            )
                          : const Icon(LucideIcons.camera, color: Color(0xFF6366F1), size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Create Your Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join $appName and manage your gym like a pro.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 32),
                
                // Full Name
                TextField(
                  controller: _nameController,
                  cursorColor: const Color(0xFF6366F1),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    hintStyle: const TextStyle(color: Colors.black38),
                    prefixIcon: const Icon(LucideIcons.user, color: Colors.black54),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Email
                TextField(
                  controller: _emailController,
                  cursorColor: const Color(0xFF6366F1),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: const TextStyle(color: Colors.black38),
                    prefixIcon: const Icon(LucideIcons.mail, color: Colors.black54),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password
                TextField(
                  controller: _passwordController,
                  cursorColor: const Color(0xFF6366F1),
                  obscureText: true,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.black38),
                    prefixIcon: const Icon(LucideIcons.lock, color: Colors.black54),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Standard Signup Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCFFF50),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: const Color(0xFFCFFF50).withOpacity(0.5),
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  height: 48,
                  child: buildGoogleSignInButton(
                    onPressed: _isLoading ? () {} : _googleSignIn,
                  ),
                ),

                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?', style: TextStyle(color: Colors.black54)),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Log In', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
