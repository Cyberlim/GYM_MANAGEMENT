import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_owner_web/core/providers/app_settings_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GymSetupPage extends ConsumerStatefulWidget {
  const GymSetupPage({super.key});

  @override
  ConsumerState<GymSetupPage> createState() => _GymSetupPageState();
}

class _GymSetupPageState extends ConsumerState<GymSetupPage> {
  String? _logoUrl;
  XFile? _logoFile;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _logoUrl = image.path;
        _logoFile = image;
      });
    }
  }

  Future<void> _submitGymSetup() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || address.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all fields.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('You are not logged in');
      }

      var request = http.MultipartRequest('POST', Uri.parse('http://localhost:5000/api/gyms/setup'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = name;
      request.fields['address'] = address;
      request.fields['contactPhone'] = phone;

      if (_logoFile != null) {
        var bytes = await _logoFile!.readAsBytes();
        var multipartFile = http.MultipartFile.fromBytes(
          'logo',
          bytes,
          filename: _logoFile!.name,
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) context.go('/start-trial');
      } else {
        var data = jsonDecode(responseData);
        throw Exception(data['message'] ?? 'Failed to setup gym');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appName = ref.watch(appNameProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(40),
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

              const Text(
                'Tell us about your gym',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s set up your workspace in $appName.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              // Gym Logo Placeholder
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        image: _logoUrl != null 
                            ? DecorationImage(image: NetworkImage(_logoUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _logoUrl == null 
                          ? const Icon(LucideIcons.imagePlus, color: Colors.black38, size: 28)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: _logoUrl != null 
                    ? TextButton.icon(
                        onPressed: () => setState(() {
                          _logoUrl = null;
                          _logoFile = null;
                        }),
                        icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                        label: const Text('Remove Logo', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    : TextButton(
                        onPressed: _pickImage,
                        child: const Text('Upload Gym Logo', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
              ),
              const SizedBox(height: 24),
              
              // Gym Name
              TextField(
                controller: _nameController,
                cursorColor: const Color(0xFF6366F1),
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Gym Name',
                  labelStyle: const TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                ),
              ),
              const SizedBox(height: 16),
              
              // Gym Address
              TextField(
                controller: _addressController,
                cursorColor: const Color(0xFF6366F1),
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Business Address',
                  labelStyle: const TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                ),
              ),
              const SizedBox(height: 16),
              
              // Phone
              TextField(
                controller: _phoneController,
                cursorColor: const Color(0xFF6366F1),
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Contact Phone',
                  labelStyle: const TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submitGymSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCFFF50),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
