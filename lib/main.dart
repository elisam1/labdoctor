import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:labdoctor/providers/lab_technician_providers.dart';
import 'package:labdoctor/screens/start_screen.dart';
import 'package:labdoctor/screens/login_screen.dart';  // Added import for LoginScreen
import 'package:labdoctor/screens/register_screen.dart'; // Added import for RegisterScreen
import 'package:labdoctor/screens/lab_technician_dashboard.dart'; // Added import for LabTechnicianDashboard
import 'package:labdoctor/screens/password_reset_screen.dart'; // Added import for PasswordResetScreen
import 'firebase_options.dart'; 
import 'package:labdoctor/services/auth_service.dart'; // Ensure we import the AuthService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LabDoctor',
      home: const StartScreen(),
      routes: {
        '/auth': (context) => const AuthWrapper(), // New route for auth flow
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const LabTechnicianDashboard(),
        '/reset-password': (context) => const PasswordResetScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(authStateProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (user) {
        if (user == null) return const LoginScreen();
        return const LabTechnicianDashboard();
      },
    );
  }
}



