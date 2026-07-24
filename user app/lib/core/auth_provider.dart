import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/core/api_service.dart';
import 'package:user_app/core/socket_service.dart';
import 'package:user_app/core/push_notification_service.dart';
import 'package:user_app/features/support/support_provider.dart';
import 'package:user_app/features/attendance/attendance_screen.dart';
import 'package:user_app/features/notifications/notifications_screen.dart';

final apiProvider = Provider((ref) => ApiService());

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  final bool isInitializing;
  final bool isLoading;
  final bool isAuthenticated;
  final bool isFirstLogin;
  final bool hasSeenOnboarding;
  final Map<String, dynamic>? user;
  final String? error;

  AuthState({
    this.isInitializing = true,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.isFirstLogin = false,
    this.hasSeenOnboarding = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isInitializing,
    bool? isLoading,
    bool? isAuthenticated,
    bool? isFirstLogin,
    bool? hasSeenOnboarding,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => checkAuth());
    return AuthState();
  }

  ApiService get _api => ref.read(apiProvider);

  Future<void> checkAuth() async {
    state = state.copyWith(isInitializing: true);
    try {
      // Add artificial delay to allow splash animation to play fully
      await Future.delayed(const Duration(seconds: 2));
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final hasSeen = prefs.getBool('has_seen_onboarding') ?? false;
      
      if (token != null) {
        final isFirst = prefs.getBool('is_first_login') ?? false;
        state = state.copyWith(
          isAuthenticated: true, 
          isFirstLogin: isFirst, 
          hasSeenOnboarding: hasSeen,
          isInitializing: false
        );
        _loadProfile();
      } else {
        state = state.copyWith(hasSeenOnboarding: hasSeen, isInitializing: false);
      }
    } catch (e) {
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _api.getProfile();
      state = state.copyWith(user: profile);
      final socketService = SocketService();
      socketService.initSocket(profile['_id']);
      
      socketService.onNewSupportMessage = (data) {
        ref.invalidate(supportMessagesProvider);
      };
      socketService.onAttendanceUpdated = (data) {
        ref.invalidate(attendanceProvider);
      };
      socketService.onNewNotification = (data) {
        ref.invalidate(notificationsProvider);
      };
      
      PushNotificationService(_api).initPushNotifications();
    } catch (e) {
      // ignore
    }
  }

  Future<bool> login(String loginId, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.login(loginId, password);
      
      final token = res['token'];
      final isFirst = res['isFirstLogin'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setBool('is_first_login', isFirst);

      // Fetch the full profile before setting authenticated state
      final profile = await _api.getProfile();
      if (profile['_id'] != null) {
        final socketService = SocketService();
        socketService.initSocket(profile['_id']);
        socketService.onNewSupportMessage = (data) {
          ref.read(supportMessagesProvider.notifier).receiveMessage(data);
        };
        socketService.onAttendanceUpdated = (data) {
          ref.invalidate(attendanceProvider);
        };
        socketService.onNewNotification = (data) {
          ref.invalidate(notificationsProvider);
        };
      }

      // Initialize push notifications
      PushNotificationService(_api).initPushNotifications();

      state = state.copyWith(
        isLoading: false, 
        isAuthenticated: true, 
        isFirstLogin: isFirst,
        user: profile,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> changePassword(String newPassword, [String? currentPassword]) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.changePassword(newPassword, currentPassword);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_login', false);
      
      state = state.copyWith(isLoading: false, isFirstLogin: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.resetPassword(email, otp, newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    state = state.copyWith(hasSeenOnboarding: true);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('is_first_login');
    SocketService().disconnect();
    state = AuthState();
  }
}
