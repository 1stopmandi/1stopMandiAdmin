import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/providers.dart';

/// Top-level handler required by firebase_messaging for background messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background processing; Firebase is already initialised by the plugin.
}

class FcmService {
  final ProviderContainer _container;

  FcmService(this._container);

  static final _tapOrderIdController =
      StreamController<String>.broadcast();

  static Stream<String> get onOrderTap => _tapOrderIdController.stream;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (iOS / macOS)
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    // Get and register token — may fail on emulators without Play Services
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (_) {}

    // Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    // App opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App was terminated, opened from notification
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _handleTap(initial);
    } catch (_) {}
  }

  Future<void> _registerToken(String token) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _container
          .read(deviceTokensRepositoryProvider)
          .register(token: token, platform: platform);
    } catch (_) {
      // Non-fatal
    }
  }

  void _handleTap(RemoteMessage message) {
    final orderId = message.data['order_id'];
    if (orderId != null) {
      _tapOrderIdController.add(orderId as String);
    }
  }
}
