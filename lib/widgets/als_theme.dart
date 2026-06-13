import 'package:flutter/material.dart';

// ── ALS Design System — Light Blue & White Theme ──────────────────────────────
class ALSTheme {
  // Core colors
  static const Color primary = Color(0xFF1565C0); // Deep blue
  static const Color primaryLight = Color(0xFF1E9AFF); // Sky blue
  static const Color accent = Color(0xFF0288D1); // Bright blue
  static const Color background = Color(0xFFF0F6FF); // Very light blue-white
  static const Color surface = Colors.white;
  static const Color surfaceBlue = Color(0xFFE3F2FD); // Light blue tint
  static const Color divider = Color(0xFFBBDEFB);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textHint = Color(0xFF90A4AE);
  static const Color textOnPrimary = Colors.white;

  // Input decoration shared across all tabs
  static InputDecoration inputDecoration(String label,
      {String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      labelStyle: const TextStyle(color: Color(0xFF546E7A), fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBBDEFB), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBBDEFB), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E9AFF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE3F2FD), width: 1.5),
      ),
    );
  }

  // Section header widget
  static Widget sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E9AFF), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1565C0),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Card-style section container
  static Widget sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBDEFB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E9AFF).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
