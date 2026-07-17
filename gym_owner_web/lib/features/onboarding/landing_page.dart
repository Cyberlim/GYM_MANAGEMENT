import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gym_owner_web/core/providers/app_settings_provider.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  int _currentImageIndex = 0;
  Timer? _timer;

  final List<String> _backgroundImages = [
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=2070&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=2070&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?q=80&w=2070&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1574680096145-d05b474e2155?q=80&w=2069&auto=format&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _backgroundImages.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appName = ref.watch(appNameProvider);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Image Carousel
          Positioned.fill(
            child: AnimatedSwitcher(
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
          ),
          
          // Dark Overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),

          // Content
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 48, 
                      vertical: 24
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.dumbbell, color: Color(0xFF6366F1), size: 32),
                            ),
                            if (!isMobile) const SizedBox(width: 16),
                            if (!isMobile)
                              Text(
                                appName,
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('Login', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => context.go('/signup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 16 : 24, 
                                  vertical: isMobile ? 12 : 16
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: Text(
                                'Get Started', 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 12 : 14,
                                )
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Hero Section
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: size.height * (isMobile ? 0.1 : 0.2),
                      horizontal: 24
                    ),
                    child: Column(
                      children: [
                        Text(
                          'The Ultimate Operating System\nfor Modern Gyms',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 36 : 56,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Manage members, track payments, and automate your operations\nall from one powerful dashboard.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        ElevatedButton(
                          onPressed: () => context.go('/signup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: const Text('Start Your Free Trial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
