import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/enrollment_service.dart';
import '../services/auth_service.dart';
import '../models/student_model.dart';

class TeacherEnrollmentsScreen extends StatefulWidget {
  const TeacherEnrollmentsScreen({super.key});

  @override
  State<TeacherEnrollmentsScreen> createState() =>
      _TeacherEnrollmentsScreenState();
}

class _TeacherEnrollmentsScreenState extends State<TeacherEnrollmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _enrolledStudents = [];
  List<Map<String, dynamic>> _pendingStudents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEnrollments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrollments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final enrollmentService = context.read<EnrollmentService>();
      final authService = context.read<AuthService>();

      print('[DEBUG] ===== LOADING ENROLLMENTS =====');
      print('[DEBUG] Current teacher: ${authService.currentTeacher?.fullName}');
      print('[DEBUG] Teacher ID: ${authService.currentTeacher?.teacherId}');

      // Load enrolled students from server
      await enrollmentService.fetchEnrolledStudents();

      // Get pending enrollments from local storage
      final pending = enrollmentService.pendingEnrollments;

      print(
          '[DEBUG] After fetch - Enrolled students count: ${enrollmentService.enrolledStudents.length}');
      print('[DEBUG] Pending students count: ${pending.length}');

      setState(() {
        _enrolledStudents =
            List<Map<String, dynamic>>.from(enrollmentService.enrolledStudents);
        _pendingStudents = List<Map<String, dynamic>>.from(pending);
        _isLoading = false;
      });

      if (_enrolledStudents.isEmpty) {
        print('[DEBUG] No enrolled students found for this teacher');
      } else {
        print(
            '[DEBUG] First enrolled student sample: ${_enrolledStudents.first}');
      }
    } catch (e) {
      print('[DEBUG] Error loading enrollments: $e');
      setState(() {
        _errorMessage = 'Failed to load enrollments: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshEnrollments() async {
    await _loadEnrollments();
  }

  void _viewStudentDetails(Map<String, dynamic> student, bool isPending) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isPending ? Icons.pending_actions : Icons.check_circle,
              color: isPending ? Colors.orange : Colors.green,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isPending ? 'Pending Enrollment' : 'Enrolled Student',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailSection('Personal Information', [
                  _buildDetailRow('LRN', student['lrn'] ?? 'N/A'),
                  _buildDetailRow(
                      'Name',
                      '${student['first_name'] ?? student['firstName'] ?? ''} '
                              '${student['last_name'] ?? student['lastName'] ?? ''} '
                              '${student['middle_name'] ?? student['middleName'] ?? ''}'
                          .trim()),
                  _buildDetailRow('Birthdate', student['birthdate'] ?? 'N/A'),
                  _buildDetailRow('Age', _calculateAge(student['birthdate'])),
                  _buildDetailRow('Sex', student['sex'] ?? 'N/A'),
                  _buildDetailRow(
                      'Contact',
                      student['contact_number'] ??
                          student['contactNumber'] ??
                          'N/A'),
                  _buildDetailRow('Email', student['email'] ?? 'N/A'),
                ]),
                const Divider(),
                _buildDetailSection('Address Information', [
                  _buildDetailRow(
                      'Street',
                      student['current_street'] ??
                          student['currentStreet'] ??
                          'N/A'),
                  _buildDetailRow(
                      'Barangay',
                      student['barangay_name'] ??
                          student['current_barangay_id']?.toString() ??
                          student['currentBarangayId']?.toString() ??
                          'N/A'),
                  _buildDetailRow(
                      'City/Municipality',
                      student['current_city'] ??
                          student['currentCity'] ??
                          'N/A'),
                  _buildDetailRow(
                      'Province',
                      student['current_province'] ??
                          student['currentProvince'] ??
                          'N/A'),
                ]),
                const Divider(),
                _buildDetailSection('Parent/Guardian Information', [
                  _buildDetailRow(
                      'Father\'s Name',
                      student['fathers_name'] ??
                          student['fathersName'] ??
                          'N/A'),
                  _buildDetailRow(
                      'Mother\'s Name',
                      student['mothers_name'] ??
                          student['mothersName'] ??
                          'N/A'),
                  _buildDetailRow(
                      'Guardian\'s Name',
                      student['guardians_name'] ??
                          student['guardiansName'] ??
                          'N/A'),
                  _buildDetailRow(
                      'Guardian\'s Contact',
                      student['guardians_contact'] ??
                          student['guardiansContact'] ??
                          'N/A'),
                ]),
                const Divider(),
                _buildDetailSection('Education Information', [
                  _buildDetailRow(
                      'Last Grade Level',
                      student['last_grade_level'] ??
                          student['lastGradeLevel'] ??
                          'N/A'),
                  _buildDetailRow(
                      'School Year',
                      student['last_school_year'] ??
                          student['lastSchoolYear'] ??
                          'N/A'),
                  _buildDetailRow(
                      'School Name',
                      student['last_school_name'] ??
                          student['lastSchoolName'] ??
                          'N/A'),
                  _buildDetailRow(
                      'School Address',
                      student['last_school_address'] ??
                          student['lastSchoolAddress'] ??
                          'N/A'),
                ]),
                const Divider(),
                _buildDetailSection('Enrollment Details', [
                  _buildDetailRow('Status', isPending ? 'Pending' : 'Enrolled',
                      valueColor: isPending ? Colors.orange : Colors.green),
                  _buildDetailRow(
                      'Enrollment Date',
                      isPending
                          ? (student['queued_at'] != null
                              ? _formatDate(student['queued_at'])
                              : 'Pending')
                          : (student['enrollment_date'] != null
                              ? _formatDate(student['enrollment_date'])
                              : (student['created_at'] != null
                                  ? _formatDate(student['created_at'])
                                  : 'N/A'))),
                  if (!isPending && student['student_id'] != null)
                    _buildDetailRow(
                        'Student ID', student['student_id'].toString()),
                  if (!isPending && student['studentId'] != null)
                    _buildDetailRow(
                        'Student ID', student['studentId'].toString()),
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (isPending)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _confirmDeletePending(student);
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0056B3),
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight:
                    valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateAge(String? birthdate) {
    if (birthdate == null || birthdate.isEmpty) return 'N/A';
    try {
      final birth = DateTime.parse(birthdate);
      final today = DateTime.now();
      int age = today.year - birth.year;
      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _confirmDeletePending(Map<String, dynamic> student) async {
    final enrollmentService = context.read<EnrollmentService>();
    final studentName =
        '${student['first_name'] ?? student['firstName'] ?? ''} '
                '${student['last_name'] ?? student['lastName'] ?? ''}'
            .trim();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pending Enrollment'),
        content: Text(
            'Are you sure you want to delete the pending enrollment for $studentName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Find the index of this pending enrollment
      final index = _pendingStudents.indexWhere((s) =>
          s['lrn'] == student['lrn'] &&
          (s['first_name'] ?? s['firstName']) ==
              (student['first_name'] ?? student['firstName']) &&
          (s['last_name'] ?? s['lastName']) ==
              (student['last_name'] ?? student['lastName']));

      if (index != -1) {
        await enrollmentService.deletePendingEnrollment(index);
        await _refreshEnrollments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pending enrollment deleted'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final teacher = authService.currentTeacher;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Enrollments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (teacher != null)
              Text(
                teacher.fullName,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFCC00),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 18),
                  const SizedBox(width: 4),
                  Text('Enrolled (${_enrolledStudents.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions, size: 18),
                  const SizedBox(width: 4),
                  Text('Pending (${_pendingStudents.length})'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshEnrollments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshEnrollments,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Enrolled Students Tab
                    _buildEnrolledList(),
                    // Pending Students Tab
                    _buildPendingList(),
                  ],
                ),
    );
  }

  Widget _buildEnrolledList() {
    if (_enrolledStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No enrolled students yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enrolled students will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshEnrollments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _enrolledStudents.length,
        itemBuilder: (context, index) {
          final student = _enrolledStudents[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _viewStudentDetails(student, false),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${student['first_name'] ?? student['firstName'] ?? ''} '
                                        '${student['last_name'] ?? student['lastName'] ?? ''}'
                                    .trim(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Enrolled',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'LRN: ${student['lrn'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoChip(
                          Icons.cake_outlined,
                          'Age: ${_calculateAge(student['birthdate'])}',
                        ),
                        _buildInfoChip(
                          Icons.phone_outlined,
                          student['contact_number'] ??
                              student['contactNumber'] ??
                              'No contact',
                        ),
                        _buildInfoChip(
                          Icons.location_on_outlined,
                          student['barangay_name'] ??
                              student['current_barangay_id']?.toString() ??
                              student['currentBarangayId']?.toString() ??
                              'N/A',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pending_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No pending enrollments',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Offline enrollments waiting to sync will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshEnrollments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingStudents.length,
        itemBuilder: (context, index) {
          final student = _pendingStudents[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _viewStudentDetails(student, true),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.pending_actions,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${student['firstName'] ?? student['first_name'] ?? ''} '
                                        '${student['lastName'] ?? student['last_name'] ?? ''}'
                                    .trim(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Pending',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'LRN: ${student['lrn'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton(
                          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') {
                              _confirmDeletePending(student);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoChip(
                          Icons.access_time,
                          student['queued_at'] != null
                              ? _formatDate(student['queued_at'])
                              : 'Pending',
                        ),
                        _buildInfoChip(
                          Icons.phone_outlined,
                          student['contactNumber'] ??
                              student['contact_number'] ??
                              'No contact',
                        ),
                        _buildInfoChip(
                          Icons.cloud_off,
                          'Offline',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
