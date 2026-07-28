import 'package:user_app/core/api_service.dart';

class PushNotificationService {
  final ApiService _apiService;

  PushNotificationService(this._apiService);

  Future<void> initPushNotifications() async {
    // Mobile push notifications logic can be added here later (e.g. using firebase_messaging)
    print('Push notifications initialization for mobile is not implemented yet.');
  }
}
