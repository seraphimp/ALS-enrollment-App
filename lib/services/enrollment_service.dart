import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../models/student_model.dart';
import '../models/barangay_model.dart';
import '../models/teacher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EnrollmentService extends ChangeNotifier {
  static const String baseUrl = 'https://als-system.online/als';

  int? _currentTeacherId;
  Teacher? _currentTeacher;

  List<Barangay> _barangays = [];
  bool _isLoading = false;
  String? _errorMessage;
  Student? _enrolledStudent;

  List<Map<String, dynamic>> _enrolledStudents = [];

  // Offline mode
  List<Map<String, dynamic>> _allPendingEnrollments = [];
  List<Map<String, dynamic>> _pendingEnrollments = [];
  bool _isOfflineMode = false;
  bool _isSyncing = false;

  // Auto-sync
  StreamSubscription<dynamic>? _connectivitySubscription;
  Timer? _autoSyncTimer;
  bool _autoSyncEnabled = true;
  DateTime? _lastAutoSyncAttempt;
  static const Duration _autoSyncCooldown = Duration(minutes: 2);
  static const int _autoSyncIntervalSeconds = 30;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<Barangay> get barangays => _barangays;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Student? get enrolledStudent => _enrolledStudent;
  bool get isOfflineMode => _isOfflineMode;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingEnrollments.length;
  List<Map<String, dynamic>> get pendingEnrollments => _pendingEnrollments;
  bool get autoSyncEnabled => _autoSyncEnabled;
  List<Map<String, dynamic>> get enrolledStudents => _enrolledStudents;
  Teacher? get currentTeacher => _currentTeacher;

  // ─── Connectivity Helpers ─────────────────────────────────────────────────

  bool _isActiveResult(ConnectivityResult r) =>
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet;

  bool _parseConnectivity(dynamic result) {
    if (result is List)
      return result.cast<ConnectivityResult>().any(_isActiveResult);
    if (result is ConnectivityResult) return _isActiveResult(result);
    return false;
  }

  Future<bool> _isConnected() async {
    try {
      return _parseConnectivity(await Connectivity().checkConnectivity());
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isServerReachable() async {
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final r = await http.get(Uri.parse('$baseUrl/api/barangays'), headers: {
          'Accept': 'application/json'
        }).timeout(const Duration(seconds: 8));
        if (r.statusCode == 200) return true;
      } catch (e) {
        print('[REACH] Attempt $attempt failed: $e');
        if (attempt < 2) await Future.delayed(const Duration(seconds: 1));
      }
    }
    return false;
  }

  // ─── Auto-Sync ────────────────────────────────────────────────────────────

  void initAutoSync() {
    _connectivitySubscription?.cancel();
    _autoSyncTimer?.cancel();

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((dynamic result) {
      if (_parseConnectivity(result) && _pendingEnrollments.isNotEmpty) {
        print('[AUTO-SYNC] Connectivity changed – attempting sync');
        _attemptAutoSync();
      }
    });

    _autoSyncTimer = Timer.periodic(
      const Duration(seconds: _autoSyncIntervalSeconds),
      (_) => _onAutoSyncTimer(),
    );
    print('[AUTO-SYNC] Listeners started');
  }

  void disposeAutoSync() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    print('[AUTO-SYNC] Listeners stopped');
  }

  Future<void> _onAutoSyncTimer() async {
    if (!_autoSyncEnabled || _pendingEnrollments.isEmpty || _isSyncing) return;
    if (await _isConnected()) {
      print('[AUTO-SYNC] Timer triggered');
      await _attemptAutoSync();
    }
  }

  Future<void> _attemptAutoSync() async {
    if (!_autoSyncEnabled || _isSyncing) return;
    final now = DateTime.now();
    if (_lastAutoSyncAttempt != null &&
        now.difference(_lastAutoSyncAttempt!) < _autoSyncCooldown) {
      print('[AUTO-SYNC] Cooldown active – skipping');
      return;
    }
    if (!await _isServerReachable()) {
      print('[AUTO-SYNC] Server not reachable – skipping');
      return;
    }
    print('[AUTO-SYNC] Starting auto-sync');
    _lastAutoSyncAttempt = now;
    await syncPendingEnrollments(isAutoSync: true);
  }

  // ─── Teacher Session ──────────────────────────────────────────────────────

  /// PRIMARY entry point – always call this at login with the full Teacher.
  /// Persists teacher to disk + preloads barangays from cache so they're
  /// available immediately when offline.
  void setCurrentTeacher(Teacher teacher) {
    _currentTeacher = teacher;
    _currentTeacherId = teacher.teacherId;
    _persistCurrentTeacher(teacher);
    _ensureBarangaysLoaded(); // ← load from cache before any enrollment
    _filterPendingForCurrentTeacher();
    notifyListeners();
    initAutoSync();
    _attemptImmediateSyncIfOnline();
    print('[SVC] setCurrentTeacher: id=${teacher.teacherId} '
        'barangayId=${teacher.barangayId} barangayName=${teacher.barangayName}');
  }

  /// Backward-compat shim - DEPRECATED: Use setCurrentTeacher instead
  @Deprecated('Use setCurrentTeacher instead')
  void setCurrentTeacherId(int teacherId, {Teacher? teacher}) {
    if (teacher != null) {
      setCurrentTeacher(teacher);
    } else {
      // If no teacher object, try to load from cache
      _loadTeacherFromCache(teacherId);
    }
  }

  // Add this method to load teacher from cache if only ID is available
  Future<void> _loadTeacherFromCache(int teacherId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_teachers');
      if (cached != null) {
        final List<dynamic> teachers = jsonDecode(cached);
        final teacherJson = teachers.firstWhere(
          (t) => t['teacher_id'] == teacherId || t['id'] == teacherId,
          orElse: () => null,
        );
        if (teacherJson != null) {
          final teacher = Teacher.fromJson(teacherJson);
          setCurrentTeacher(teacher);
        }
      }
    } catch (e) {
      print('[SVC] Error loading teacher from cache: $e');
    }
  }

  // Add this method to ensure teacher is loaded with all properties
  Future<void> ensureTeacherLoaded() async {
    if (_currentTeacher == null) {
      await restoreCurrentTeacher();
    }

    // If still null after restore, try to load from SharedPreferences directly
    if (_currentTeacher == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final teacherJson = prefs.getString('current_teacher');
        if (teacherJson != null) {
          final teacher = Teacher.fromJson(jsonDecode(teacherJson));
          _currentTeacher = teacher;
          _currentTeacherId = teacher.teacherId;
          print('[SVC] Emergency teacher restore: id=${teacher.teacherId}');
        }
      } catch (e) {
        print('[SVC] Emergency teacher restore failed: $e');
      }
    }
  }

  void clearCurrentTeacherId() {
    _currentTeacherId = null;
    _currentTeacher = null;
    _pendingEnrollments.clear();
    _clearPersistedTeacher();
    disposeAutoSync();
    notifyListeners();
  }

  // ── Persist / restore teacher across restarts ─────────────────────────────

  Future<void> _persistCurrentTeacher(Teacher teacher) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_teacher', jsonEncode(teacher.toJson()));
      print('[SVC] Teacher persisted to disk');
    } catch (e) {
      print('[SVC] Error persisting teacher: $e');
    }
  }

  Future<void> _clearPersistedTeacher() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_teacher');
    } catch (_) {}
  }

  /// Restore teacher from disk on app cold start (call from main or splash).
  Future<bool> restoreCurrentTeacher() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('current_teacher');
      if (raw != null) {
        final teacher = Teacher.fromJson(jsonDecode(raw));
        _currentTeacher = teacher;
        _currentTeacherId = teacher.teacherId;
        _filterPendingForCurrentTeacher();
        notifyListeners();
        print('[SVC] Restored teacher id=${teacher.teacherId} '
            'barangayId=${teacher.barangayId}');
        return true;
      }
    } catch (e) {
      print('[SVC] Error restoring teacher: $e');
    }
    return false;
  }

  // ── Ensure barangays are in memory before any enrollment ─────────────────

  /// Called every time a teacher is set.  If the in-memory list is empty it
  /// loads from SharedPreferences immediately (no network) so that
  /// _applyTeacherBarangayToStudent() can resolve city names even offline.
  void _ensureBarangaysLoaded() {
    if (_barangays.isNotEmpty) return;
    _loadCachedBarangaysSync(); // fire-and-forget async
  }

  Future<void> _loadCachedBarangaysSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_barangays');
      if (cached != null) {
        _barangays = (jsonDecode(cached) as List)
            .map((j) => Barangay.fromJson(j))
            .toList();
        print('[SVC] Barangays loaded from cache: ${_barangays.length}');
      } else {
        _loadDummyBarangays();
        print('[SVC] Barangays – using dummy data (no cache yet)');
      }
      notifyListeners();
    } catch (e) {
      print('[SVC] Error in _loadCachedBarangaysSync: $e');
      _loadDummyBarangays();
    }
  }

  Future<void> _attemptImmediateSyncIfOnline() async {
    if (_pendingEnrollments.isEmpty) return;
    if (await _isConnected() && await _isServerReachable()) {
      print('[AUTO-SYNC] Immediate sync on login');
      await syncPendingEnrollments(isAutoSync: true);
    }
  }

  void _filterPendingForCurrentTeacher() {
    if (_currentTeacherId == null) {
      _pendingEnrollments.clear();
    } else {
      _pendingEnrollments = _allPendingEnrollments
          .where((e) => e['teacher_id'] == _currentTeacherId)
          .toList();
    }
    print('[DEBUG] Filtered pending for teacher $_currentTeacherId: '
        '${_pendingEnrollments.length} enrollments');
  }

  // ─── Barangays ────────────────────────────────────────────────────────────

  Future<void> fetchBarangays() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!await _isConnected()) {
        await _loadCachedBarangays();
        _isOfflineMode = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(Uri.parse('$baseUrl/api/barangays'),
          headers: {
            'Accept': 'application/json'
          }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('data')) {
          _barangays =
              (data['data'] as List).map((j) => Barangay.fromJson(j)).toList();
        } else if (data is List) {
          _barangays = data.map((j) => Barangay.fromJson(j)).toList();
        } else {
          throw Exception('Invalid barangays response format');
        }
        await _cacheBarangays();
        _isOfflineMode = false;
        print('[DEBUG] Loaded ${_barangays.length} barangays from API');
      } else {
        _errorMessage = 'Failed to load barangays: ${response.statusCode}';
        await _loadCachedBarangays();
        _isOfflineMode = _barangays.isNotEmpty;
      }
    } catch (e) {
      _errorMessage = 'Error loading barangays: ${e.toString()}';
      await _loadCachedBarangays();
      _isOfflineMode = _barangays.isNotEmpty;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cacheBarangays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_barangays',
          jsonEncode(_barangays.map((b) => b.toJson()).toList()));
    } catch (e) {
      print('[DEBUG] Error caching barangays: $e');
    }
  }

  Future<void> _loadCachedBarangays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_barangays');
      if (cached != null) {
        _barangays = (jsonDecode(cached) as List)
            .map((j) => Barangay.fromJson(j))
            .toList();
        print('[DEBUG] Loaded ${_barangays.length} barangays from cache');
      } else {
        _loadDummyBarangays();
      }
    } catch (e) {
      print('[DEBUG] Error loading cached barangays: $e');
      _loadDummyBarangays();
    }
  }

  // ─── Fetch Enrolled Students ──────────────────────────────────────────────

  Future<void> fetchEnrolledStudents() async {
    if (_currentTeacherId == null) {
      print('[DEBUG] No teacher ID set');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!await _isConnected()) {
        _errorMessage =
            'No internet connection. Please go online to view enrolled students.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final url =
          '$baseUrl/api/get_teacher_enrollments.php?teacher_id=$_currentTeacherId';
      final response = await http.get(Uri.parse(url), headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 15));

      print('[DEBUG] Fetch enrolled students: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final rd = json.decode(response.body);
          if (rd is Map) {
            if (rd['success'] == true && rd['data'] != null)
              _enrolledStudents = List<Map<String, dynamic>>.from(rd['data']);
            else if (rd.containsKey('data'))
              _enrolledStudents = List<Map<String, dynamic>>.from(rd['data']);
            else if (rd.containsKey('students'))
              _enrolledStudents =
                  List<Map<String, dynamic>>.from(rd['students']);
            else
              _enrolledStudents = [];
          } else if (rd is List) {
            _enrolledStudents = List<Map<String, dynamic>>.from(rd);
          } else {
            _enrolledStudents = [];
          }
          print('[DEBUG] Loaded ${_enrolledStudents.length} enrolled students');
        } catch (e) {
          print('[DEBUG] Error parsing response: $e');
          _enrolledStudents = [];
          _errorMessage = 'Error parsing server response';
        }
      } else {
        _errorMessage = 'Server error (${response.statusCode}).';
        _enrolledStudents = [];
      }
    } catch (e) {
      _errorMessage = 'Error loading enrolled students: ${e.toString()}';
      _enrolledStudents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTeacherEnrollments() async {
    await Future.wait([fetchEnrolledStudents(), loadPendingEnrollments()]);
  }

  // ─── Pending Enrollment Queue ─────────────────────────────────────────────

  Future<void> loadPendingEnrollments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('pending_enrollments');
      if (cached != null) {
        _allPendingEnrollments =
            List<Map<String, dynamic>>.from(jsonDecode(cached));
        print('[DEBUG] Loaded ${_allPendingEnrollments.length} total pending');
        _filterPendingForCurrentTeacher();
      }
    } catch (e) {
      print('[DEBUG] Error loading pending enrollments: $e');
    }
  }

  Future<void> _savePendingEnrollments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'pending_enrollments', jsonEncode(_allPendingEnrollments));
    } catch (e) {
      print('[DEBUG] Error saving pending enrollments: $e');
    }
  }

  String _constructQrCodeUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/als/admin-web/'))
      return 'https://als-system.online$path';
    if (path.startsWith('../'))
      return 'https://als-system.online/als/admin-web/${path.substring(3)}';
    if (path.startsWith('qrcodes/'))
      return 'https://als-system.online/als/admin-web/$path';
    if (path.startsWith('/'))
      return 'https://als-system.online/als/admin-web$path';
    return 'https://als-system.online/als/admin-web/qrcodes/$path';
  }

  // ─── Apply Teacher Barangay ───────────────────────────────────────────────

  /// FIXED: Always apply teacher's barangay to ensure offline enrollments
  /// have the correct barangay assignment
  Future<void> _applyTeacherBarangayToStudent(Student student) async {
    // Ensure teacher is loaded before applying
    await ensureTeacherLoaded();

    final teacher = _currentTeacher;

    // Always apply the teacher's barangay if available, regardless of existing value
    // This ensures offline enrollments always get the correct barangay
    if (teacher != null && teacher.barangayId != null) {
      // Force set the teacher's barangay ID
      student.currentBarangayId = teacher.barangayId;
      print(
          '[DEBUG] _applyTeacherBarangay: FORCE SET barangayId=${teacher.barangayId}');

      // Resolve city from in-memory list (loaded from cache, available offline)
      final barangay = _barangays.cast<Barangay?>().firstWhere(
            (b) => b?.barangayId == teacher.barangayId,
            orElse: () => null,
          );

      student.currentCity =
          (barangay?.city != null && barangay!.city!.isNotEmpty)
              ? '${barangay.city} City'
              : 'La Carlota City';

      print('[DEBUG] _applyTeacherBarangay: city=${student.currentCity}');

      // If same address is yes, also set permanent address fields
      if (student.sameAddress == 'yes') {
        student.permanentBarangayId = student.currentBarangayId;
        student.permanentCity = student.currentCity;
        student.permanentStreet = student.currentStreet;
        student.permanentProvince = student.currentProvince;
        student.permanentCountry = student.currentCountry;
        student.permanentZip = student.currentZip;
      }
    } else {
      print('[DEBUG] _applyTeacherBarangay: teacher=$teacher '
          'barangayId=${teacher?.barangayId} – cannot apply barangay');

      // If no teacher barangay, use a default as fallback
      if (student.currentBarangayId == null) {
        student.currentBarangayId = 1; // Default to Barangay I
        student.currentCity = 'La Carlota City';
        print('[DEBUG] _applyTeacherBarangay: using default barangay 1');
      }
    }
  }

  // ─── Add to Pending Queue ─────────────────────────────────────────────────

  Future<void> _addToPendingQueue(Student student) async {
    if (_currentTeacherId == null) return;

    // IMPORTANT: Apply teacher barangay BEFORE serializing to ensure it's saved
    await _applyTeacherBarangayToStudent(student);

    // Ensure we have a barangay ID after applying
    if (student.currentBarangayId == null) {
      student.currentBarangayId = _currentTeacher?.barangayId ?? 1;
      student.currentCity = 'La Carlota City';
      print(
          '[DEBUG] _addToPendingQueue: fallback barangay=${student.currentBarangayId}');
    }

    // Generate a temporary ID for offline enrollments
    final tempId = 'TEMP-${DateTime.now().millisecondsSinceEpoch}';

    final enrollmentData = <String, dynamic>{
      ...student.toJson(),
      'temp_id': tempId, // Add temporary ID
      'teacher_id': _currentTeacherId,
      'teacher_barangay_id':
          _currentTeacher?.barangayId, // IMPORTANT: Store teacher's barangay ID
      'enrollment_date': DateTime.now().toIso8601String().split('T')[0],
      'queued_at': DateTime.now().toIso8601String(),
      'status': 'pending',
    };

    // Explicitly set current_barangay_id to ensure it's in the JSON
    enrollmentData['current_barangay_id'] = student.currentBarangayId;

    // Ensure city is set
    if (enrollmentData['current_city'] == null ||
        enrollmentData['current_city']!.isEmpty) {
      enrollmentData['current_city'] = student.currentCity ?? 'La Carlota City';
    }

    // Set default values for other address fields if missing
    enrollmentData['current_street'] ??= student.currentStreet ?? '';
    enrollmentData['current_province'] ??=
        student.currentProvince ?? 'Negros Occidental';
    enrollmentData['current_country'] ??=
        student.currentCountry ?? 'Philippines';
    enrollmentData['current_zip'] ??= student.currentZip ?? '6130';

    // Handle same address
    if (student.sameAddress == 'yes') {
      enrollmentData['permanent_barangay_id'] =
          enrollmentData['current_barangay_id'];
      enrollmentData['permanent_street'] = enrollmentData['current_street'];
      enrollmentData['permanent_city'] = enrollmentData['current_city'];
      enrollmentData['permanent_province'] = enrollmentData['current_province'];
      enrollmentData['permanent_country'] = enrollmentData['current_country'];
      enrollmentData['permanent_zip'] = enrollmentData['current_zip'];
    }

    // Remove any problematic fields
    enrollmentData.remove('barangay');

    _allPendingEnrollments.add(enrollmentData);
    await _savePendingEnrollments();
    _filterPendingForCurrentTeacher();

    print(
        '[DEBUG] QUEUED ENROLLMENT - Barangay ID: ${enrollmentData['current_barangay_id']}, '
        'Teacher Barangay ID: ${enrollmentData['teacher_barangay_id']}, '
        'City: ${enrollmentData['current_city']}, '
        'Teacher ID: $_currentTeacherId');
    print('[DEBUG] Total pending: ${_allPendingEnrollments.length}');

    if (_autoSyncEnabled && !_isSyncing) {
      Future.microtask(() async {
        if (await _isConnected() && await _isServerReachable()) {
          await syncPendingEnrollments(isAutoSync: true);
        }
      });
    }
  }

  Future<void> _removeFromPendingIfExists(
      Map<String, dynamic> submittedData) async {
    if (_allPendingEnrollments.isEmpty) return;
    final before = _allPendingEnrollments.length;
    _allPendingEnrollments.removeWhere((p) =>
        p['teacher_id'] == _currentTeacherId &&
        p['firstName'] == submittedData['firstName'] &&
        p['lastName'] == submittedData['lastName'] &&
        p['lrn'] == submittedData['lrn']);
    if (before != _allPendingEnrollments.length) {
      await _savePendingEnrollments();
      _filterPendingForCurrentTeacher();
    }
  }

  // ─── Sync ─────────────────────────────────────────────────────────────────

  Future<void> syncPendingEnrollments({bool isAutoSync = false}) async {
    if (_pendingEnrollments.isEmpty) {
      print('[SYNC] No pending');
      return;
    }
    if (_isSyncing) {
      print('[SYNC] Already syncing');
      return;
    }

    print('[SYNC] ===== ${isAutoSync ? 'AUTO' : 'MANUAL'} SYNC STARTED =====');

    if (!await _isConnected()) {
      print('[SYNC] No internet – aborting');
      if (!isAutoSync) {
        _errorMessage = 'No internet connection.';
        notifyListeners();
      }
      return;
    }

    // Ensure teacher is loaded before syncing
    await ensureTeacherLoaded();

    _isSyncing = true;
    notifyListeners();

    final List<Map<String, dynamic>> failed = [];
    final List<Map<String, dynamic>> succeeded = [];
    int successCount = 0;

    for (var enrollment
        in List<Map<String, dynamic>>.from(_pendingEnrollments)) {
      try {
        final Map<String, dynamic> data = Map.from(enrollment);
        data.remove('queued_at');
        data.remove('status');
        data.remove('temp_id');

        // IMPORTANT FIX: Use teacher_barangay_id from enrollment if available,
        // otherwise use current teacher's barangay ID
        int? barangayId;

        // First try to get from enrollment data
        if (data['current_barangay_id'] != null) {
          barangayId = data['current_barangay_id'] is int
              ? data['current_barangay_id']
              : int.tryParse(data['current_barangay_id'].toString());
        }

        // If not found, try teacher_barangay_id from enrollment
        if (barangayId == null && data['teacher_barangay_id'] != null) {
          barangayId = data['teacher_barangay_id'] is int
              ? data['teacher_barangay_id']
              : int.tryParse(data['teacher_barangay_id'].toString());
        }

        // If still not found, use current teacher's barangay
        if (barangayId == null && _currentTeacher?.barangayId != null) {
          barangayId = _currentTeacher!.barangayId;
        }

        // Final fallback
        barangayId ??= 1;

        // Set the barangay ID in the payload
        data['current_barangay_id'] = barangayId;

        // Ensure address fields have defaults
        data['current_street'] ??= '';
        data['current_city'] ??= 'La Carlota City';
        data['current_province'] ??= 'Negros Occidental';
        data['current_country'] ??= 'Philippines';
        data['current_zip'] ??= '6130';

        // Add teacher_id back for the API
        data['teacher_id'] = _currentTeacherId;

        if (!data.containsKey('permanent_barangay_id') &&
            (enrollment['same_address'] == 'yes' ||
                enrollment['sameAddress'] == 'yes')) {
          data['permanent_barangay_id'] = data['current_barangay_id'];
          data['permanent_street'] = data['current_street'];
          data['permanent_city'] = data['current_city'];
          data['permanent_province'] = data['current_province'];
          data['permanent_country'] = data['current_country'];
          data['permanent_zip'] = data['current_zip'];
        }

        data.removeWhere((k, v) => v is Map || v is List || v is Function);

        print(
            '[SYNC] Sending enrollment with barangay_id: ${data['current_barangay_id']}');

        final response = await http
            .post(
              Uri.parse('$baseUrl/api/enroll.php'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
              },
              body: json.encode(data),
            )
            .timeout(const Duration(seconds: 15));

        print('[SYNC] Response: ${response.statusCode}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            String body = response.body.trim();
            if (body.contains('<')) {
              final s = body.indexOf('{');
              if (s != -1) body = body.substring(s);
            }
            final parsed = json.decode(body);
            if (parsed['success'] == true) {
              successCount++;
              succeeded.add(enrollment);
              print('[SYNC] Enrollment synced successfully');
            } else {
              failed.add(enrollment);
              print('[SYNC] success=false: ${parsed['message']}');
            }
          } catch (_) {
            successCount++;
            succeeded.add(enrollment);
          }
        } else {
          failed.add(enrollment);
          print('[SYNC] HTTP error: ${response.statusCode}');
        }
      } catch (e) {
        failed.add(enrollment);
        print('[SYNC] Error: $e');
      }
    }

    for (var s in succeeded) {
      _allPendingEnrollments.removeWhere((e) =>
          e['queued_at'] == s['queued_at'] &&
          e['teacher_id'] == s['teacher_id']);
    }

    await _savePendingEnrollments();
    _filterPendingForCurrentTeacher();

    _isSyncing = false;
    if (successCount > 0) _isOfflineMode = false;
    notifyListeners();

    print('[SYNC] Done – Success: $successCount, Failed: ${failed.length}');
    print('[SYNC] ===== ${isAutoSync ? 'AUTO' : 'MANUAL'} SYNC ENDED =====');
  }

  Future<void> manualSync() async {
    print('[MANUAL SYNC] Triggered by user');
    await syncPendingEnrollments(isAutoSync: false);
  }

  void toggleAutoSync({bool? enable}) {
    _autoSyncEnabled = enable ?? !_autoSyncEnabled;
    print('[AUTO-SYNC] ${_autoSyncEnabled ? 'Enabled' : 'Disabled'}');
    if (_autoSyncEnabled) _attemptImmediateSyncIfOnline();
    notifyListeners();
  }

  // ─── Delete Pending ───────────────────────────────────────────────────────

  Future<void> deletePendingEnrollment(int index) async {
    if (index < 0 || index >= _pendingEnrollments.length) return;
    final toDelete = _pendingEnrollments[index];
    final before = _allPendingEnrollments.length;
    _allPendingEnrollments.removeWhere((e) =>
        e['queued_at'] == toDelete['queued_at'] &&
        e['teacher_id'] == toDelete['teacher_id']);
    if (before != _allPendingEnrollments.length) {
      await _savePendingEnrollments();
      _filterPendingForCurrentTeacher();
      notifyListeners();
    }
  }

  Future<void> deleteAllPendingEnrollments() async {
    final before = _allPendingEnrollments.length;
    _allPendingEnrollments
        .removeWhere((e) => e['teacher_id'] == _currentTeacherId);
    if (before != _allPendingEnrollments.length) {
      await _savePendingEnrollments();
      _filterPendingForCurrentTeacher();
      notifyListeners();
    }
  }

  // ─── Submit Enrollment ────────────────────────────────────────────────────

  Future<bool> submitEnrollment(Student student) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('[DEBUG] ===== STARTING ENROLLMENT =====');
      print('[DEBUG] teacher id=$_currentTeacherId '
          'barangayId=${_currentTeacher?.barangayId} '
          'barangays in memory=${_barangays.length}');

      if (_currentTeacherId == null) {
        _errorMessage = 'No teacher logged in. Please login first.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Ensure teacher is loaded with all properties
      await ensureTeacherLoaded();

      // If barangays cache wasn't loaded yet, load it now (blocking)
      if (_barangays.isEmpty) await _loadCachedBarangaysSync();

      // IMPORTANT: Stamp teacher barangay before branching online/offline
      await _applyTeacherBarangayToStudent(student);

      print('[DEBUG] After apply: barangayId=${student.currentBarangayId} '
          'city=${student.currentCity}');

      // Ensure we have a barangay ID
      if (student.currentBarangayId == null) {
        student.currentBarangayId = _currentTeacher?.barangayId ?? 1;
        student.currentCity = 'La Carlota City';
        print('[DEBUG] Fallback set: barangayId=${student.currentBarangayId}');
      }

      // ── Offline path ──────────────────────────────────────────────────
      if (!await _isConnected()) {
        print('[DEBUG] Offline – queueing');
        await _addToPendingQueue(student);
        _isOfflineMode = true;
        _isLoading = false;
        _errorMessage =
            'No internet. Enrollment saved and will sync when connected.';
        notifyListeners();
        return true;
      }

      // ── Online path ───────────────────────────────────────────────────
      final Map<String, dynamic> studentData = student.toJson();
      studentData['teacher_id'] = _currentTeacherId;

      // Ensure barangay_id is set in the payload
      studentData['current_barangay_id'] = student.currentBarangayId ??
          _currentTeacher?.barangayId ??
          studentData['barangay_id'] ??
          1;

      // Set default address fields
      studentData['current_street'] ??= student.currentStreet ?? '';
      studentData['current_city'] ??= student.currentCity ?? 'La Carlota City';
      studentData['current_province'] ??=
          student.currentProvince ?? 'Negros Occidental';
      studentData['current_country'] ??=
          student.currentCountry ?? 'Philippines';
      studentData['current_zip'] ??= student.currentZip ?? '6130';

      if (student.sameAddress == 'yes') {
        studentData['permanent_barangay_id'] =
            studentData['current_barangay_id'];
        studentData['permanent_street'] = studentData['current_street'];
        studentData['permanent_city'] = studentData['current_city'];
        studentData['permanent_province'] = studentData['current_province'];
        studentData['permanent_country'] = studentData['current_country'];
        studentData['permanent_zip'] = studentData['current_zip'];
      }

      studentData.removeWhere((k, v) => v == null);

      print('[DEBUG] Payload barangay=${studentData['current_barangay_id']} '
          'city=${studentData['current_city']}');

      http.Response response;
      try {
        response = await http
            .post(
              Uri.parse('$baseUrl/api/enroll.php'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
              },
              body: json.encode(studentData),
            )
            .timeout(const Duration(seconds: 20));
      } on TimeoutException {
        print('[DEBUG] Timeout – queueing');
        await _addToPendingQueue(student);
        _isOfflineMode = true;
        _isLoading = false;
        _errorMessage =
            'Server timeout. Enrollment saved and will sync automatically.';
        notifyListeners();
        return true;
      } catch (e) {
        print('[DEBUG] Network error – queueing: $e');
        await _addToPendingQueue(student);
        _isOfflineMode = true;
        _isLoading = false;
        _errorMessage =
            'Network error. Enrollment saved and will sync automatically.';
        notifyListeners();
        return true;
      }

      print('[DEBUG] Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        String body = response.body.trim();
        if (body.contains('<')) {
          final s = body.indexOf('{');
          if (s != -1) body = body.substring(s);
        }

        try {
          final rd = json.decode(body);
          if (rd['success'] == true) {
            final data = rd['data'];
            student.studentId = data['student_id']?.toString();
            student.qrCode = _constructQrCodeUrl(data['qr_code']?.toString());
            _enrolledStudent = student;
            _isOfflineMode = false;
            _isLoading = false;
            await _removeFromPendingIfExists(studentData);
            notifyListeners();
            print('[DEBUG] ✅ Enrollment successful!');
            return true;
          } else {
            _errorMessage = rd['message'] ?? 'Enrollment failed';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (_) {
          if (response.body.contains('"success":true') ||
              response.body.contains('"student_id":')) {
            final idMatch =
                RegExp(r'"student_id":"([^"]+)"').firstMatch(response.body);
            if (idMatch != null) {
              student.studentId = idMatch.group(1);
              final qrMatch =
                  RegExp(r'"qr_code":"([^"]+)"').firstMatch(response.body);
              if (qrMatch != null)
                student.qrCode = _constructQrCodeUrl(qrMatch.group(1));
              _enrolledStudent = student;
              _isOfflineMode = false;
              _isLoading = false;
              await _removeFromPendingIfExists(studentData);
              notifyListeners();
              return true;
            }
          }
          _errorMessage = 'Invalid server response. Please try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else if (response.statusCode >= 500) {
        print('[DEBUG] Server error – queueing');
        await _addToPendingQueue(student);
        _isOfflineMode = true;
        _isLoading = false;
        _errorMessage =
            'Server error. Enrollment saved and will sync automatically.';
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            'Enrollment failed (${response.statusCode}). Please check your data.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, st) {
      _errorMessage = 'Unexpected error: ${e.toString()}';
      print('[DEBUG] EXCEPTION: $e\n$st');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Utilities ────────────────────────────────────────────────────────────

  Future<bool> testConnection() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/api/barangays'), headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 8));
      return r.statusCode == 200;
    } catch (e) {
      print('[DEBUG] Connection test failed: $e');
      return false;
    }
  }

  void _loadDummyBarangays() {
    _barangays = [
      Barangay(barangayId: 1, name: 'Barangay I', city: 'La Carlota'),
      Barangay(barangayId: 2, name: 'Barangay II', city: 'La Carlota'),
      Barangay(barangayId: 3, name: 'Barangay III', city: 'La Carlota'),
      Barangay(barangayId: 4, name: 'Ara-al', city: 'La Carlota'),
      Barangay(barangayId: 5, name: 'Ayungon', city: 'La Carlota'),
      Barangay(barangayId: 6, name: 'Balabag', city: 'La Carlota'),
      Barangay(barangayId: 7, name: 'Batuan', city: 'La Carlota'),
      Barangay(barangayId: 8, name: 'Cubay', city: 'La Carlota'),
      Barangay(barangayId: 9, name: 'Haguimit', city: 'La Carlota'),
      Barangay(barangayId: 10, name: 'La Granja', city: 'La Carlota'),
      Barangay(barangayId: 11, name: 'Nagasi', city: 'La Carlota'),
      Barangay(barangayId: 12, name: 'Punao', city: 'La Carlota'),
      Barangay(barangayId: 13, name: 'Rocky Hill', city: 'La Carlota'),
      Barangay(barangayId: 14, name: 'San Miguel', city: 'La Carlota'),
    ];
  }

  void clearEnrolledStudent() {
    _enrolledStudent = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeAutoSync();
    super.dispose();
  }
}
