import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:js_interop';
import 'package:user_app/core/api_service.dart';

@JS('window.subscribeToWebPush')
external JSPromise? _subscribeToWebPush(JSString vapidPublicKey);

class PushNotificationService {
  final ApiService _apiService;

  PushNotificationService(this._apiService);

  Future<void> initPushNotifications() async {
    if (!kIsWeb) return;

    try {
      // 1. Get VAPID public key from backend
      final response = await _apiService.get('/notifications/vapid-public-key');
      final publicKey = response['publicKey'] as String?;

      if (publicKey == null || publicKey.isEmpty) {
        print('No VAPID public key provided by backend');
        return;
      }

      // 2. Subscribe via JS interop
      final jsPromise = _subscribeToWebPush(publicKey.toJS);
      if (jsPromise == null) {
        print('Web Push not supported in this browser');
        return;
      }

      final result = await jsPromise.toDart;
      if (result != null) {
        final subscriptionString = (result as JSString).toDart;
        final subscription = jsonDecode(subscriptionString);

        // 3. Send subscription to backend
        await _apiService.post('/notifications/subscribe', {
          'subscription': subscription
        });
        print('Successfully subscribed to push notifications.');
      }
    } catch (e) {
      print('Error initializing push notifications: $e');
    }
  }
}
