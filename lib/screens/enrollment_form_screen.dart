import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_model.dart';
import '../services/enrollment_service.dart';
import '../services/auth_service.dart';
import '../widgets/personal_info_tab.dart';
import '../widgets/address_info_tab.dart';
import '../widgets/parent_info_tab.dart';
import '../widgets/education_tab.dart';
import '../widgets/accessibility_tab.dart';
import '../widgets/terms_tab.dart';
import '../screens/success_screen.dart';
import '../screens/teacher_enrollment_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

// ── Design tokens — Light Blue & White Theme ──────────────────────────────────
const _primary = Color(0xFF1565C0);
const _accent = Color(0xFF1E9AFF);
const _bg = Color(0xFFF0F6FF);
const _surface = Colors.white;
const _surfaceBlue = Color(0xFFE3F2FD);
const _border = Color(0xFFBBDEFB);
const _success = Color(0xFF10B981);
const _warning = Color(0xFFF59E0B);
const _error = Color(0xFFEF4444);
const _textPrimary = Color(0xFF0D1B2A);
const _textSec = Color(0xFF546E7A);
const _textHint = Color(0xFF90A4AE);

// ── Reusable helpers ──────────────────────────────────────────────────────────
Widget _dialogHeader({
  required IconData icon,
  required String title,
  required VoidCallback onClose,
  Widget? trailing,
}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _accent],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
        if (trailing != null) trailing,
        IconButton(
          onPressed: onClose,
          icon: Icon(Icons.close_rounded,
              color: Colors.white.withOpacity(0.80), size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );

Widget _progressDialog(
        {required Color color,
        required String title,
        required String message}) =>
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(color)),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 13, color: _textSec, height: 1.4)),
        ]),
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────

class EnrollmentFormScreen extends StatefulWidget {
  const EnrollmentFormScreen({super.key});

  @override
  State<EnrollmentFormScreen> createState() => _EnrollmentFormScreenState();
}

class _EnrollmentFormScreenState extends State<EnrollmentFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  late Student _student;
  bool _termsAccepted = false;
  bool _hasInternet = true;
  Timer? _connectivityTimer;
  bool _isAutoRefreshing = false;
  int _refreshAttempts = 0;
  static const int maxRefreshAttempts = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // Rebuild bottom bar when tab changes
    _tabController.addListener(() => setState(() {}));
    _student =
        Student(lastName: '', firstName: '', enrollmentDate: DateTime.now());
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkConnectivityAndLoad());
    _startConnectivityMonitoring();
    _setupTeacherListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  void _setupTeacherListener() {
    context.read<AuthService>().addListener(_onTeacherChanged);
  }

  void _onTeacherChanged() => _refreshPendingEnrollments();

  Future<void> _refreshPendingEnrollments() async {
    await context.read<EnrollmentService>().loadPendingEnrollments();
  }

  void _startConnectivityMonitoring() {
    _connectivityTimer = Timer.periodic(
        const Duration(seconds: 10), (_) => _checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final hasInternet = result != ConnectivityResult.none;
    if (hasInternet != _hasInternet) {
      setState(() => _hasInternet = hasInternet);
      await _refreshPendingEnrollments();
      _triggerAutoRefresh();
    }
  }

  Future<void> _triggerAutoRefresh() async {
    if (_isAutoRefreshing) return;
    setState(() {
      _isAutoRefreshing = true;
      _refreshAttempts++;
    });

    final svc = context.read<EnrollmentService>();

    if (_hasInternet) {
      await svc.fetchBarangays();
      await _refreshPendingEnrollments();
      if (svc.pendingEnrollments.isNotEmpty) {
        await svc.syncPendingEnrollments();
        await _refreshPendingEnrollments();
      }
      if (mounted) {
        _snack(
          message: svc.pendingEnrollments.isEmpty
              ? 'Online · Data synchronized'
              : 'Online · ${svc.pendingEnrollments.length} pending sync',
          icon: Icons.cloud_done_rounded,
          color: svc.pendingEnrollments.isEmpty ? _success : _warning,
        );
      }
    } else {
      await _refreshPendingEnrollments();
      if (mounted && svc.pendingEnrollments.isNotEmpty) {
        _snack(
          message:
              'Offline · ${svc.pendingEnrollments.length} enrollment(s) pending',
          icon: Icons.cloud_off_rounded,
          color: _warning,
        );
      }
    }

    setState(() => _isAutoRefreshing = false);
    _refreshAttempts = 0;
  }

  Future<void> _checkConnectivityAndLoad() async {
    final result = await Connectivity().checkConnectivity();
    setState(() => _hasInternet = result != ConnectivityResult.none);
    await context.read<EnrollmentService>().fetchBarangays();
    await _refreshPendingEnrollments();
  }

  void _snack(
      {required String message, required IconData icon, required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _syncPendingEnrollments() async {
    final svc = context.read<EnrollmentService>();
    await _refreshPendingEnrollments();

    if (svc.pendingEnrollments.isEmpty) {
      _snack(
          message: 'No pending enrollments to sync.',
          icon: Icons.info_rounded,
          color: _accent);
      return;
    }
    if (!_hasInternet) {
      _snack(
          message: 'No internet connection. Please check your network.',
          icon: Icons.wifi_off_rounded,
          color: _warning);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _progressDialog(
        color: _accent,
        title: 'Syncing Enrollments',
        message: 'Uploading ${svc.pendingEnrollments.length} enrollment(s)...',
      ),
    );

    await svc.manualSync();
    await _refreshPendingEnrollments();

    if (mounted) {
      Navigator.of(context).pop();
      final rem = svc.pendingEnrollments.length;
      _snack(
        message: rem == 0
            ? 'All enrollments synced successfully!'
            : '$rem enrollment(s) failed. Will retry automatically.',
        icon: rem == 0 ? Icons.check_circle_rounded : Icons.warning_rounded,
        color: rem == 0 ? _success : _warning,
      );
    }
  }

  Future<void> _showPendingEnrollmentsDialog() async {
    final svc = context.read<EnrollmentService>();
    await _refreshPendingEnrollments();

    if (svc.pendingEnrollments.isEmpty) {
      _snack(
          message: 'No pending enrollments',
          icon: Icons.info_rounded,
          color: _accent);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _warning.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogHeader(
              icon: Icons.cloud_off_rounded,
              title: 'Pending Enrollments',
              onClose: () => Navigator.of(context).pop(),
              trailing: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _confirmDeleteAllPending();
                },
                icon: const Icon(Icons.delete_sweep_rounded,
                    size: 16, color: _error),
                label: const Text('Delete All',
                    style: TextStyle(color: _error, fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ),

            // Count chip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _warning.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _warning.withOpacity(0.35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.pending_actions_rounded,
                      size: 14, color: _warning),
                  const SizedBox(width: 6),
                  Text('${svc.pendingEnrollments.length} awaiting sync',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _warning)),
                ]),
              ),
            ),

            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: svc.pendingEnrollments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = svc.pendingEnrollments[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: _surfaceBlue.withOpacity(0.60),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _warning.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pending_actions_rounded,
                            color: _warning, size: 20),
                      ),
                      title: Text(
                        '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                            fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LRN: ${p['lrn'] ?? 'N/A'}',
                              style: const TextStyle(
                                  fontSize: 12, color: _textSec)),
                          if (p['queued_at'] != null)
                            Text(
                              'Queued: ${DateTime.parse(p['queued_at']).toLocal().toString().split('.')[0]}',
                              style: const TextStyle(
                                  fontSize: 10, color: _textHint),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: _error, size: 20),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _confirmDeletePending(index);
                        },
                      ),
                      onTap: () => _showPendingEnrollmentDetails(p),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSec,
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 14)),
                  ),
                ),
                if (_hasInternet && svc.pendingEnrollments.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _syncPendingEnrollments();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Sync All',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _confirmDeletePending(int index) async {
    final svc = context.read<EnrollmentService>();
    final p = svc.pendingEnrollments[index];
    final name = '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}';
    final confirm = await _confirmDialog(
        title: 'Delete Enrollment',
        message: 'Remove enrollment for $name?',
        confirmLabel: 'Delete');
    if (confirm == true) {
      await svc.deletePendingEnrollment(index);
      await _refreshPendingEnrollments();
      if (mounted)
        _snack(
            message: 'Pending enrollment deleted',
            icon: Icons.delete_rounded,
            color: _success);
    }
  }

  Future<void> _confirmDeleteAllPending() async {
    final svc = context.read<EnrollmentService>();
    final count = svc.pendingEnrollments.length;
    final confirm = await _confirmDialog(
        title: 'Delete All Pending',
        message: 'Remove all $count pending enrollment(s)?',
        confirmLabel: 'Delete All');
    if (confirm == true) {
      await svc.deleteAllPendingEnrollments();
      await _refreshPendingEnrollments();
      if (mounted)
        _snack(
            message: 'All pending enrollments deleted',
            icon: Icons.delete_rounded,
            color: _success);
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: _error.withOpacity(0.10), shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded,
                  color: _error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: _textSec, height: 1.4)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSec,
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showPendingEnrollmentDetails(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogHeader(
              icon: Icons.info_rounded,
              title: 'Enrollment Details',
              onClose: () => Navigator.of(context).pop(),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                _detailRow(Icons.person_rounded, 'Name',
                    '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'),
                _detailRow(Icons.numbers_rounded, 'LRN', p['lrn'] ?? 'N/A'),
                _detailRow(
                    Icons.cake_rounded, 'Birthdate', p['birthdate'] ?? 'N/A'),
                _detailRow(Icons.phone_rounded, 'Contact',
                    p['contactNumber'] ?? 'N/A'),
                _detailRow(Icons.location_on_rounded, 'Address',
                    '${p['current_barangay_id'] ?? ''} ${p['current_street'] ?? ''}, ${p['current_city'] ?? ''}'),
                if (p['queued_at'] != null)
                  _detailRow(
                      Icons.schedule_rounded,
                      'Queued',
                      DateTime.parse(p['queued_at'])
                          .toLocal()
                          .toString()
                          .split('.')[0]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: _accent),
          ),
          const SizedBox(width: 10),
          SizedBox(
              width: 76,
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _textSec))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary))),
        ]),
      );

  void _updateStudent(Student s) => setState(() => _student = s);
  void _updateTermsAcceptance(bool v) => setState(() => _termsAccepted = v);

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _snack(
          message: 'Please fill in all required fields',
          icon: Icons.error_outline_rounded,
          color: _error);
      return;
    }
    if (!_termsAccepted) {
      _snack(
          message: 'You must accept the Terms and Conditions',
          icon: Icons.gavel_rounded,
          color: _warning);
      _tabController.animateTo(5);
      return;
    }

    final svc = context.read<EnrollmentService>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _progressDialog(
        color: _hasInternet ? _accent : _warning,
        title: _hasInternet ? 'Submitting Enrollment' : 'Saving Offline',
        message: _hasInternet
            ? 'Please wait while we process the enrollment...'
            : 'Saving to local storage for later sync...',
      ),
    );

    try {
      final success = await svc.submitEnrollment(_student);
      if (mounted) Navigator.of(context).pop();

      if (success) {
        await _refreshPendingEnrollments();

        if (!_hasInternet || svc.isOfflineMode) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _warning.withOpacity(0.40)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                        color: _warning.withOpacity(0.12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.cloud_off_rounded,
                        size: 32, color: _warning),
                  ),
                  const SizedBox(height: 16),
                  const Text('Saved Offline',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary)),
                  const SizedBox(height: 8),
                  const Text(
                    'Your enrollment has been saved locally and will be automatically synced when internet connection is available.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: _textSec, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => SuccessScreen(
                                student: _student, isOfflineMode: true)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _warning,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Continue',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => SuccessScreen(student: _student)));
        }
      } else {
        _snack(
            message: svc.errorMessage ?? 'Enrollment failed',
            icon: Icons.error_rounded,
            color: _error);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _snack(
          message: 'Error: ${e.toString()}',
          icon: Icons.error_rounded,
          color: _error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.watch<EnrollmentService>();
    final hasPending = svc.pendingEnrollments.isNotEmpty;
    final isSyncing = svc.isSyncing;
    // ── Track current tab for Next/Submit button ──────────────────────────────
    final isLastTab = _tabController.index == 5;

    return Scaffold(
      backgroundColor: _bg,

      // ── FAB ─────────────────────────────────────────────────────────────────
      floatingActionButton: hasPending
          ? FloatingActionButton.extended(
              onPressed: isSyncing ? null : _syncPendingEnrollments,
              backgroundColor:
                  isSyncing ? _textHint : (_hasInternet ? _accent : _warning),
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              icon: isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Icon(
                      _hasInternet
                          ? Icons.sync_rounded
                          : Icons.cloud_off_rounded,
                      color: Colors.white,
                      size: 20),
              label: Text(
                isSyncing
                    ? 'Syncing...'
                    : _hasInternet
                        ? 'Sync Now (${svc.pendingCount})'
                        : 'Offline (${svc.pendingCount})',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              tooltip: _hasInternet
                  ? 'Manually sync pending enrollments'
                  : 'No internet – sync unavailable',
            )
          : null,

      // ── AppBar ───────────────────────────────────────────────────────────────
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _accent],
            ),
          ),
        ),
        titleSpacing: 16,
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.school_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Alternative Learning System',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              if (auth.currentTeacher != null)
                Text(
                  'Teacher: ${auth.currentTeacher!.fullName}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withOpacity(0.80)),
                ),
            ]),
          ),
        ]),
        actions: [
          // View enrollments
          IconButton(
            icon: Icon(Icons.list_alt_rounded,
                color: Colors.white.withOpacity(0.90), size: 22),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TeacherEnrollmentsScreen())),
            tooltip: 'View My Enrollments',
          ),

          // Auto-sync spinner
          if (_isAutoRefreshing)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)),
                  ),
                  const SizedBox(width: 5),
                  Text('Auto',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.90))),
                ]),
              ),
            ),

          // Pending badge
          if (hasPending)
            IconButton(
              icon: Stack(clipBehavior: Clip.none, children: [
                Icon(Icons.pending_actions_rounded,
                    color: Colors.white.withOpacity(0.90), size: 22),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: _warning, shape: BoxShape.circle),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${svc.pendingEnrollments.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ]),
              onPressed: _showPendingEnrollmentsDialog,
              tooltip: 'View pending enrollments',
            ),

          // Connectivity chip
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: Row(children: [
              Icon(
                _hasInternet ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                size: 12,
                color: _hasInternet
                    ? const Color(0xFF80FFBD)
                    : const Color(0xFFFFE082),
              ),
              const SizedBox(width: 4),
              Text(
                _hasInternet ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _hasInternet
                      ? const Color(0xFF80FFBD)
                      : const Color(0xFFFFE082),
                ),
              ),
            ]),
          ),

          // Logout
          if (auth.currentTeacher != null)
            IconButton(
              icon: Icon(Icons.logout_rounded,
                  color: Colors.white.withOpacity(0.90), size: 20),
              tooltip: 'Logout',
              onPressed: () => showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                            color: _error.withOpacity(0.10),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.logout_rounded,
                            color: _error, size: 26),
                      ),
                      const SizedBox(height: 16),
                      const Text('Logout',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary)),
                      const SizedBox(height: 8),
                      Text(
                        hasPending
                            ? 'You have unsynced offline enrollments. They will be lost if you logout. Continue?'
                            : 'Are you sure you want to logout?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: _textSec, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _textSec,
                              side: const BorderSide(color: _border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              auth.logout();
                              Navigator.of(context)
                                  .pushNamedAndRemoveUntil('/', (r) => false);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _error,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Logout',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
        ],

        // ── Tab bar ────────────────────────────────────────────────────────────
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Column(children: [
            Container(
                height: 2.5, color: const Color(0xFFFFCC00).withOpacity(0.85)),
            Container(
              color: _surface,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: _accent,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: _primary,
                unselectedLabelColor: _textSec,
                labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_rounded, size: 15),
                    SizedBox(width: 5),
                    Text('Personal')
                  ])),
                  Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.location_on_rounded, size: 15),
                    SizedBox(width: 5),
                    Text('Address')
                  ])),
                  Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.family_restroom_rounded, size: 15),
                    SizedBox(width: 5),
                    Text('Parent')
                  ])),
                  Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.school_rounded, size: 15),
                    SizedBox(width: 5),
                    Text('Education')
                  ])),
                  Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.accessibility_rounded, size: 15),
                    SizedBox(width: 5),
                    Text('Access')
                  ])),
                  Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.gavel_rounded, size: 15),
                    SizedBox(width: 5),
                    Text('Terms')
                  ])),
                ],
              ),
            ),
          ]),
        ),
      ),

      body: Form(
        key: _formKey,
        child: Column(children: [
          // ── Status banners ─────────────────────────────────────────────────
          if (_isAutoRefreshing)
            _banner(
              icon: Icons.sync_rounded,
              message: _hasInternet
                  ? 'Switched to ONLINE · Syncing data...'
                  : 'Switched to OFFLINE · Loading cached data...',
              color: _accent,
              spinner: true,
            ),

          if (!_hasInternet)
            _banner(
              icon: Icons.wifi_off_rounded,
              message:
                  'You are offline · Enrollment will be saved locally and synced when online',
              color: _warning,
            ),

          if (_hasInternet && hasPending)
            _banner(
              icon: Icons.sync_rounded,
              message: isSyncing
                  ? 'Auto-syncing ${svc.pendingEnrollments.length} enrollment(s) in background...'
                  : '${svc.pendingEnrollments.length} enrollment(s) pending · Tap "Sync Now" to upload',
              color: _accent,
              spinner: isSyncing,
            ),

          // ── ID info bar ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: _surfaceBlue,
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: (_hasInternet ? _accent : _warning).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _hasInternet ? Icons.cloud_rounded : Icons.cloud_off_rounded,
                  size: 15,
                  color: _hasInternet ? _accent : _warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _hasInternet
                      ? 'Student ID will be generated upon submission'
                      : 'Offline Mode · ID will be generated when online',
                  style: TextStyle(
                    fontSize: 12,
                    color: _hasInternet ? _primary : _warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ]),
          ),

          // ── Tab content ───────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                PersonalInfoTab(
                    student: _student, onStudentUpdated: _updateStudent),
                AddressInfoTab(
                    student: _student, onStudentUpdated: _updateStudent),
                ParentInfoTab(
                    student: _student, onStudentUpdated: _updateStudent),
                EducationTab(
                    student: _student, onStudentUpdated: _updateStudent),
                AccessibilityTab(
                    student: _student, onStudentUpdated: _updateStudent),
                TermsTab(
                    termsAccepted: _termsAccepted,
                    onTermsChanged: _updateTermsAcceptance),
              ],
            ),
          ),

          // ── Bottom action bar ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: _surface,
              border: const Border(top: BorderSide(color: _border)),
              boxShadow: [
                BoxShadow(
                    color: _accent.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4))
              ],
            ),
            child: Row(children: [
              // Reset
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _formKey.currentState?.reset();
                    setState(() {
                      _student = Student(
                          lastName: '',
                          firstName: '',
                          enrollmentDate: DateTime.now());
                      _termsAccepted = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSec,
                    side: const BorderSide(color: _border, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reset',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              // ── Next tab  /  Submit (last tab only) ──────────────────────
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: isLastTab
                      // ── Submit button (Terms tab) ─────────────────────────
                      ? ElevatedButton.icon(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasInternet ? _accent : _warning,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13)),
                          ),
                          icon: Icon(
                              _hasInternet
                                  ? Icons.how_to_reg_rounded
                                  : Icons.save_rounded,
                              size: 20),
                          label: Text(
                            _hasInternet ? 'Enroll Student' : 'Save Offline',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        )
                      // ── Next button (all other tabs) ──────────────────────
                      : ElevatedButton.icon(
                          onPressed: () => _tabController
                              .animateTo(_tabController.index + 1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13)),
                          ),
                          icon:
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                          label: const Text('Next',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _banner({
    required IconData icon,
    required String message,
    required Color color,
    bool spinner = false,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        color: color.withOpacity(0.10),
        child: Row(children: [
          if (spinner)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color)),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500))),
        ]),
      );
}
