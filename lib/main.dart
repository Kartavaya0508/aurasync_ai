import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/dashboard_screen.dart';
import 'screens/auth_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fetching Supabase credentials from the build environment
  // This prevents sensitive keys from being exposed on GitHub
  const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Initialize Supabase with a fallback check
  await Supabase.initialize(
    url: supabaseUrl.isEmpty ? 'YOUR_SUPABASE_URL_HERE' : supabaseUrl,
    anonKey: supabaseAnonKey.isEmpty ? 'YOUR_ANON_KEY_HERE' : supabaseAnonKey,
  );

  // Initialize Notifications
  await NotificationService.init();

  final cameras = await availableCameras();
  runApp(AuraSyncApp(cameras: cameras));
}

class AuraSyncApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const AuraSyncApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AuraSync AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E676),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Redirect to Dashboard if logged in, otherwise AuthScreen
      home: session != null
          ? DashboardScreen(cameras: cameras)
          : AuthScreen(cameras: cameras),
    );
  }
}
