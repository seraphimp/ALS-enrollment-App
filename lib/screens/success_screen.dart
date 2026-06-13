import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/student_model.dart';
import 'enrollment_form_screen.dart';

class SuccessScreen extends StatefulWidget {
  final Student student;
  final String? qrCodeUrl;
  final bool isOfflineMode;

  const SuccessScreen({
    super.key,
    required this.student,
    this.qrCodeUrl,
    this.isOfflineMode = false,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _contentController;
  late AnimationController _pulseController;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _checkOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _playSuccessSequence();
  }

  Future<void> _playSuccessSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _checkController.forward();
    HapticFeedback.mediumImpact();

    // Only try to play sound if online
    if (!widget.isOfflineMode) {
      try {
        await _audioPlayer.play(
          UrlSource(
              'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'),
        );
      } catch (_) {
        // Silently fail - don't let sound errors affect UI
        print('[SUCCESS] Sound playback failed (offline or network issue)');
      }
    }

    await Future.delayed(const Duration(milliseconds: 400));
    _contentController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Helper method to build QR placeholder
  Widget _buildQrPlaceholder() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2F4E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E9AFF).withOpacity(0.20),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isOfflineMode
                ? Icons.cloud_off_rounded
                : Icons.qr_code_2_rounded,
            size: 48,
            color: Colors.white.withOpacity(0.25),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isOfflineMode
                ? 'QR code will be\nassigned when synced'
                : 'QR code will be\navailable after sync',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build QR image from network
  Widget _buildNetworkQr(String url) {
    // Don't try to load network image when offline
    if (widget.isOfflineMode) {
      return _buildQrPlaceholder();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E9AFF).withOpacity(0.20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.network(
        url.startsWith('http')
            ? url
            : 'https://als-system.online/als/admin-web/${widget.qrCodeUrl}',
        width: 180,
        height: 180,
        errorBuilder: (context, error, stackTrace) {
          return _buildQrPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: 180,
            height: 180,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xFF1E9AFF),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrData = 'ALS Student: ${widget.student.studentId}\n'
        'Name: ${widget.student.lastName}, ${widget.student.firstName} ${widget.student.middleName}\n'
        'LRN: ${widget.student.lrn ?? "N/A"}';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1628),
                  Color(0xFF0D2137),
                  Color(0xFF0A1628),
                ],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1E9AFF).withOpacity(0.12),
                  width: 1,
                ),
              ),
            ),
          ),
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E9AFF).withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00D4AA).withOpacity(0.10),
                  width: 1,
                ),
              ),
            ),
          ),

          // Offline indicator top bar
          if (widget.isOfflineMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 8,
                  left: 16,
                  right: 16,
                ),
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Saved Offline · Will sync automatically when online',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFFF59E0B).withOpacity(0.9),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── Animated check circle ──────────────────────────────
                  ScaleTransition(
                    scale: _checkScale,
                    child: FadeTransition(
                      opacity: _checkOpacity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring (animated pulse)
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF00D4AA).withOpacity(0.25),
                                    const Color(0xFF00D4AA).withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Inner circle
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF00D4AA),
                                  Color(0xFF00B08C),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF00D4AA).withOpacity(0.40),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Heading ────────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Text(
                            widget.isOfflineMode
                                ? 'Saved for Sync'
                                : 'Enrollment Complete',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isOfflineMode
                                ? 'Will be submitted once you\'re back online'
                                : 'Student has been enrolled successfully',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.55),
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Student card ───────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2040),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF1E9AFF).withOpacity(0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.30),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Card header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1E4D8C),
                                    Color(0xFF1565C0),
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${widget.student.lastName}, ${widget.student.firstName} ${widget.student.middleName ?? ""}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            widget.isOfflineMode
                                                ? 'Pending Assignment'
                                                : 'ID: ${widget.student.studentId ?? "Pending"}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white70,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // QR section
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Text(
                                    widget.isOfflineMode
                                        ? 'QR Code (Pending)'
                                        : 'Student QR Code',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.50),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // QR Code Display Logic
                                  if (widget.qrCodeUrl != null &&
                                      widget.qrCodeUrl!.isNotEmpty &&
                                      !widget.isOfflineMode)
                                    _buildNetworkQr(widget.qrCodeUrl!)
                                  else if (widget.student.studentId != null &&
                                      !widget.isOfflineMode)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1E9AFF)
                                                .withOpacity(0.20),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: QrImageView(
                                        data: qrData,
                                        version: QrVersions.auto,
                                        size: 180.0,
                                      ),
                                    )
                                  else
                                    _buildQrPlaceholder(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Action buttons ─────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // View Summary button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _showSummaryDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E9AFF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.receipt_long_rounded,
                                  size: 20),
                              label: const Text(
                                'View Enrollment Summary',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Enroll Another button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EnrollmentFormScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.20),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: Icon(
                                Icons.person_add_rounded,
                                size: 20,
                                color: Colors.white.withOpacity(0.70),
                              ),
                              label: Text(
                                'Enroll Another Student',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.70),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSummaryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F2040),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF1E9AFF).withOpacity(0.18),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E4D8C), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_turned_in_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Enrollment Summary',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded,
                          color: Colors.white.withOpacity(0.70), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Dialog content
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummarySection('Personal Information', [
                      _buildSummaryRow(Icons.badge_rounded, 'Student ID',
                          widget.student.studentId ?? 'Pending'),
                      _buildSummaryRow(
                        Icons.person_rounded,
                        'Full Name',
                        '${widget.student.lastName}, ${widget.student.firstName} ${widget.student.middleName ?? ""}',
                      ),
                      _buildSummaryRow(
                        Icons.cake_rounded,
                        'Birth Date',
                        widget.student.birthdate?.toString().split(' ')[0] ??
                            '',
                      ),
                      _buildSummaryRow(Icons.phone_rounded, 'Contact',
                          widget.student.contactNumber ?? ''),
                      _buildSummaryRow(
                          Icons.wc_rounded, 'Sex', widget.student.sex),
                      _buildSummaryRow(Icons.favorite_rounded, 'Civil Status',
                          widget.student.civilStatus),
                    ]),
                    const SizedBox(height: 16),
                    _buildSummarySection('Address', [
                      _buildSummaryRow(
                        Icons.location_on_rounded,
                        'Current',
                        '${widget.student.currentHouseNo ?? ""} ${widget.student.currentStreet ?? ""}, ${widget.student.currentCity}',
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildSummarySection('Education', [
                      _buildSummaryRow(
                        Icons.school_rounded,
                        'Last Grade Level',
                        widget.student.lastGradeLevel ?? 'N/A',
                      ),
                      _buildSummaryRow(Icons.auto_stories_rounded,
                          'ALS Program', widget.student.alsProgram ?? 'N/A'),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF1E9AFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E9AFF),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16, color: const Color(0xFF1E9AFF).withOpacity(0.70)),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.50),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
