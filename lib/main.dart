import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (safely wrapped for demo/first-run purposes)
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');
    }
  } catch (e) {
    debugPrint('Firebase init failed - google-services.json or configurations might be missing');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return MaterialApp(
      title: 'Flutter IoT App',
      theme: AppTheme.darkTheme,
      home: user == null ? const LoginScreen() : const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
