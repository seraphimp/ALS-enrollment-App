import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/enrollment_service.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const ALSEnrollmentApp());
}

class ALSEnrollmentApp extends StatelessWidget {
  const ALSEnrollmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Create services once and wire them together ───────────────────────
    final enrollmentService = EnrollmentService();
    final authService = AuthService();

    // KEY FIX: give AuthService a reference to EnrollmentService so that
    // loginTeacher() can forward the full Teacher object (including barangayId)
    // to EnrollmentService — this is what stamps the teacher's assigned
    // barangay onto offline enrollments.
    authService.setEnrollmentService(enrollmentService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: enrollmentService),
      ],
      child: MaterialApp(
        title: 'ALS Enrollment System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF0056B3),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0056B3),
            secondary: const Color(0xFFFFCC00),
          ),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0056B3),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0056B3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0056B3), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
