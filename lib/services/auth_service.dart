import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/teacher.dart';
import '../services/enrollment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static const String baseUrl = 'https://als-system.online/als/api/teachers';

  List<Teacher> _teachers = [];
  Teacher? _currentTeacher;
  bool _isLoading = false;
  String? _errorMessage;

  // ── NEW: reference to EnrollmentService so login/logout can sync it ──────
  EnrollmentService? _enrollmentService;

  /// Call this once after both services are created (e.g. in main.dart or
  /// the MultiProvider setup) so AuthService can forward teacher info.
  void setEnrollmentService(EnrollmentService service) {
    _enrollmentService = service;
    // If there's already a logged in teacher, sync it
    if (_currentTeacher != null) {
      _enrollmentService!.setCurrentTeacher(_currentTeacher!);
      print('[AUTH] Synced existing teacher to EnrollmentService on init');
    }
  }

  List<Teacher> get teachers => _teachers;
  Teacher? get currentTeacher => _currentTeacher;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentTeacher != null;

  // ── Fetch teachers ────────────────────────────────────────────────────────

  Future<void> fetchTeachers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          _teachers = data.map((j) => Teacher.fromJson(j)).toList();
          print('[AUTH] Loaded ${_teachers.length} teachers from API');
          await _cacheTeachers();
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to load teachers';
          await loadCachedTeachers();
        }
      } else {
        _errorMessage = 'Server error: ${response.statusCode}';
        await loadCachedTeachers();
      }
    } catch (e) {
      _errorMessage = 'Network error';
      await loadCachedTeachers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cacheTeachers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_teachers',
          jsonEncode(_teachers.map((t) => t.toJson()).toList()));
      print('[AUTH] Teachers cached locally');
    } catch (e) {
      print('[AUTH] Cache error: $e');
    }
  }

  Future<void> loadCachedTeachers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_teachers');
      if (cachedData != null) {
        _teachers = (jsonDecode(cachedData) as List)
            .map((j) => Teacher.fromJson(j))
            .toList();
        print('[AUTH] Loaded ${_teachers.length} teachers from cache');
      } else {
        print('[AUTH] No cached teachers found');
      }
    } catch (e) {
      print('[AUTH] Load cache error: $e');
    }
    notifyListeners();
  }

  // ── Login / Logout ────────────────────────────────────────────────────────

  void loginTeacherById(int teacherId) {
    final teacher = getTeacherById(teacherId);
    if (teacher != null) loginTeacher(teacher);
  }

  /// Sets the logged-in teacher and forwards the full Teacher object to
  /// EnrollmentService so offline enrollments get the correct barangay.
  void loginTeacher(Teacher teacher) {
    _currentTeacher = teacher;
    _errorMessage = null;

    // ── KEY FIX: push teacher into EnrollmentService ──────────────────────
    if (_enrollmentService != null) {
      _enrollmentService!.setCurrentTeacher(teacher);
      print('[AUTH] EnrollmentService updated with teacher '
          '${teacher.teacherId} / barangayId=${teacher.barangayId}');
    } else {
      // Fallback: at least set the ID (barangay won't be available offline)
      print('[AUTH] WARNING: EnrollmentService not linked – '
          'call setEnrollmentService() in your provider setup.');
    }

    // Persist current teacher to SharedPreferences for offline recovery
    _persistCurrentTeacher(teacher);

    print('[AUTH] Logged in: ${teacher.fullName} (ID: ${teacher.teacherId})');
    notifyListeners();
  }

  Future<void> _persistCurrentTeacher(Teacher teacher) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_teacher', jsonEncode(teacher.toJson()));
      print('[AUTH] Teacher persisted to disk for offline recovery');
    } catch (e) {
      print('[AUTH] Error persisting teacher: $e');
    }
  }

  Future<void> _clearPersistedTeacher() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_teacher');
    } catch (_) {}
  }

  /// Restore teacher from disk on app cold start
  Future<bool> restoreCurrentTeacher() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('current_teacher');
      if (raw != null) {
        final teacher = Teacher.fromJson(jsonDecode(raw));
        _currentTeacher = teacher;

        // Also sync to EnrollmentService if available
        if (_enrollmentService != null) {
          _enrollmentService!.setCurrentTeacher(teacher);
        }

        print('[AUTH] Restored teacher from disk: id=${teacher.teacherId}');
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('[AUTH] Error restoring teacher: $e');
    }
    return false;
  }

  void logout() {
    print('[AUTH] Logging out: ${_currentTeacher?.fullName}');

    // Clear teacher from EnrollmentService too
    if (_enrollmentService != null) {
      _enrollmentService!.clearCurrentTeacherId();
    }

    _currentTeacher = null;
    _clearPersistedTeacher();

    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Teacher? getTeacherById(int teacherId) {
    try {
      return _teachers.firstWhere((t) => t.teacherId == teacherId);
    } catch (_) {
      print('[AUTH] Teacher not found with ID: $teacherId');
      return null;
    }
  }

  void updateCurrentTeacher(Teacher teacher) {
    _currentTeacher = teacher;
    final idx = _teachers.indexWhere((t) => t.teacherId == teacher.teacherId);
    if (idx != -1) _teachers[idx] = teacher;

    // Keep EnrollmentService in sync when teacher data is updated
    if (_enrollmentService != null) {
      _enrollmentService!.setCurrentTeacher(teacher);
    }

    // Update persisted teacher
    _persistCurrentTeacher(teacher);

    notifyListeners();
  }

  List<Teacher> searchTeachers(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return _teachers
        .where((t) =>
            t.firstName.toLowerCase().contains(q) ||
            t.lastName.toLowerCase().contains(q) ||
            (t.middleName?.toLowerCase().contains(q) ?? false) ||
            t.fullName.toLowerCase().contains(q))
        .toList();
  }

  List<Teacher> getTeachersByBarangay(int barangayId) =>
      _teachers.where((t) => t.barangayId == barangayId).toList();

  Future<void> refreshTeachers() => fetchTeachers();

  Teacher? getTeacherByEmail(String email) {
    try {
      return _teachers
          .firstWhere((t) => t.email?.toLowerCase() == email.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  bool validateCredentials(String email, String password) =>
      getTeacherByEmail(email) != null;
}
