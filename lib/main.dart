import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/local/token_storage.dart';
import 'core/network/api_client.dart';
import 'core/providers/providers.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Restore saved auth token before first frame
  final savedToken = await TokenStorage.instance.read();
  if (savedToken != null) {
    ApiClient.instance.setToken(savedToken);
  }

  final container = ProviderContainer();

  // Initialise FCM after Firebase is ready — non-fatal if unavailable (e.g. emulator)
  final fcm = FcmService(container);
  try {
    await fcm.init();
  } catch (_) {
    // FCM unavailable (no Play Services on emulator, or network error); app continues normally
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AdminApp(),
    ),
  );
}
