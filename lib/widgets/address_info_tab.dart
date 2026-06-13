import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_model.dart';
import '../models/barangay_model.dart';
import '../models/teacher.dart';
import '../services/enrollment_service.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────
class _C {
  static const primary = Color(0xFF1565C0);
  static const primaryMid = Color(0xFF1976D2);
  static const primaryLight = Color(0xFF42A5F5);
  static const sky50 = Color(0xFFF0F7FF);
  static const sky100 = Color(0xFFDCEEFD);
  static const sky200 = Color(0xFFBBDEFB);
  static const sky300 = Color(0xFF90CAF9);
  static const accent = Color(0xFF0288D1);
  static const success = Color(0xFF26A69A);
  static const textDark = Color(0xFF0D2B5E);
  static const textMid = Color(0xFF3D5A8A);
  static const textLight = Color(0xFF7A9CC4);
  static const divider = Color(0xFFCDE4F8);
  static const white = Colors.white;
}

// ─────────────────────────────────────────────────────────────
//  Reusable styled input decoration
// ─────────────────────────────────────────────────────────────
InputDecoration _fieldDeco(String label,
    {IconData? icon, bool disabled = false}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: disabled ? _C.textLight : _C.textMid,
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
    ),
    prefixIcon: icon != null
        ? Icon(icon, size: 18, color: disabled ? _C.sky300 : _C.primaryLight)
        : null,
    filled: true,
    fillColor: disabled ? const Color(0xFFF2F8FF) : _C.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _C.sky200, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _C.primaryMid, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDCEEFD), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

// ─────────────────────────────────────────────────────────────
//  Section header widget
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: _C.primaryMid.withOpacity(0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _C.white, size: 17),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _C.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Info chip (locked field indicator)
// ─────────────────────────────────────────────────────────────
class _LockedFieldRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _LockedFieldRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.sky200, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _C.sky300),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _C.textLight,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13.5,
                        color: _C.textMid,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _C.sky100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 11, color: _C.textLight),
                SizedBox(width: 3),
                Text('Auto',
                    style: TextStyle(fontSize: 10.5, color: _C.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Main Tab
// ─────────────────────────────────────────────────────────────
class AddressInfoTab extends StatefulWidget {
  final Student student;
  final Function(Student) onStudentUpdated;

  const AddressInfoTab({
    super.key,
    required this.student,
    required this.onStudentUpdated,
  });

  @override
  State<AddressInfoTab> createState() => _AddressInfoTabState();
}

class _AddressInfoTabState extends State<AddressInfoTab>
    with SingleTickerProviderStateMixin {
  late TextEditingController _currentHouseNoController;
  late TextEditingController _currentStreetController;
  late TextEditingController _permanentHouseNoController;
  late TextEditingController _permanentStreetController;
  late TextEditingController _currentCityController;
  late TextEditingController _currentProvinceController;
  late TextEditingController _currentCountryController;
  late TextEditingController _currentZipController;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Teacher? _currentTeacher;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  void _initializeControllers() {
    _currentHouseNoController =
        TextEditingController(text: widget.student.currentHouseNo);
    _currentStreetController =
        TextEditingController(text: widget.student.currentStreet);
    _permanentHouseNoController =
        TextEditingController(text: widget.student.permanentHouseNo);
    _permanentStreetController =
        TextEditingController(text: widget.student.permanentStreet);
    _currentCityController =
        TextEditingController(text: widget.student.currentCity);
    _currentProvinceController =
        TextEditingController(text: widget.student.currentProvince);
    _currentCountryController =
        TextEditingController(text: widget.student.currentCountry);
    _currentZipController =
        TextEditingController(text: widget.student.currentZip);
  }

  void _autoSetBarangayFromTeacher() {
    if (_initialized) return;
    final authService = context.read<AuthService>();
    _currentTeacher = authService.currentTeacher;

    if (_currentTeacher != null &&
        _currentTeacher!.barangayId != null &&
        widget.student.currentBarangayId == null) {
      widget.student.currentBarangayId = _currentTeacher!.barangayId;

      final enrollmentService = context.read<EnrollmentService>();
      final barangay = enrollmentService.barangays.firstWhere(
        (b) => b.barangayId == _currentTeacher!.barangayId,
        orElse: () =>
            Barangay(barangayId: 0, name: 'Unknown', city: 'La Carlota'),
      );

      if (barangay.city != null && barangay.city!.isNotEmpty) {
        widget.student.currentCity = '${barangay.city} City';
        _currentCityController.text = widget.student.currentCity!;
      }
      widget.onStudentUpdated(widget.student);
      setState(() => _initialized = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _autoSetBarangayFromTeacher());
  }

  @override
  void didUpdateWidget(AddressInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.student.currentCity != oldWidget.student.currentCity)
      _currentCityController.text = widget.student.currentCity ?? '';
    if (widget.student.currentProvince != oldWidget.student.currentProvince)
      _currentProvinceController.text = widget.student.currentProvince ?? '';
    if (widget.student.currentCountry != oldWidget.student.currentCountry)
      _currentCountryController.text = widget.student.currentCountry ?? '';
    if (widget.student.currentZip != oldWidget.student.currentZip)
      _currentZipController.text = widget.student.currentZip ?? '';
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _currentHouseNoController.dispose();
    _currentStreetController.dispose();
    _permanentHouseNoController.dispose();
    _permanentStreetController.dispose();
    _currentCityController.dispose();
    _currentProvinceController.dispose();
    _currentCountryController.dispose();
    _currentZipController.dispose();
    super.dispose();
  }

  void _updateStudent() {
    widget.student.currentHouseNo = _currentHouseNoController.text;
    widget.student.currentStreet = _currentStreetController.text;
    widget.student.permanentHouseNo = _permanentHouseNoController.text;
    widget.student.permanentStreet = _permanentStreetController.text;
    widget.onStudentUpdated(widget.student);
  }

  Barangay? _getBarangayById(int? id) {
    if (id == null) return null;
    return context.read<EnrollmentService>().barangays.firstWhere(
          (b) => b.barangayId == id,
          orElse: () =>
              Barangay(barangayId: 0, name: 'Unknown', city: 'Unknown'),
        );
  }

  void _onCurrentBarangayChanged(int? value) {
    if (value == null) return;
    setState(() {
      widget.student.currentBarangayId = value;
      final barangay = _getBarangayById(value);
      if (barangay != null &&
          barangay.city != null &&
          barangay.city!.isNotEmpty) {
        widget.student.currentCity = '${barangay.city} City';
        _currentCityController.text = widget.student.currentCity!;
      }
      _updateStudent();
    });
  }

  // ── Dropdown decoration ───────────────────────────────────
  InputDecoration _dropDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: _C.textMid, fontSize: 13.5, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, size: 18, color: _C.primaryLight),
        filled: true,
        fillColor: _C.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.sky200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.primaryMid, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  // ── Spacing helper ─────────────────────────────────────────
  static const _gap = SizedBox(height: 12);
  static const _sectionGap = SizedBox(height: 20);

  @override
  Widget build(BuildContext context) {
    final enrollmentService = context.watch<EnrollmentService>();
    final authService = context.watch<AuthService>();
    _currentTeacher = authService.currentTeacher;

    final lacarlotaBarangays = enrollmentService.barangays
        .where((b) =>
            b.city != null && b.city!.toLowerCase().contains('la carlota'))
        .toList();

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          color: _C.sky50,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Teacher barangay banner ──────────────────
                if (_currentTeacher != null &&
                    _currentTeacher!.barangayName != null)
                  _TeacherBanner(barangayName: _currentTeacher!.barangayName!),

                // ══════════════════════════════════════════════
                //  CURRENT ADDRESS
                // ══════════════════════════════════════════════
                const _SectionHeader(
                  title: 'Current Address',
                  icon: Icons.location_on_rounded,
                ),
                _sectionGap,

                // House No
                TextFormField(
                  controller: _currentHouseNoController,
                  style: const TextStyle(color: _C.textDark, fontSize: 14),
                  decoration: _fieldDeco(
                    'House No. / Lot / Bldg.',
                    icon: Icons.home_rounded,
                  ),
                  onChanged: (_) => _updateStudent(),
                ),
                _gap,

                // Street
                TextFormField(
                  controller: _currentStreetController,
                  style: const TextStyle(color: _C.textDark, fontSize: 14),
                  decoration: _fieldDeco(
                    'Street',
                    icon: Icons.signpost_rounded,
                  ),
                  onChanged: (_) => _updateStudent(),
                ),
                _gap,

                // Barangay dropdown
                DropdownButtonFormField<int>(
                  value: widget.student.currentBarangayId,
                  style: const TextStyle(color: _C.textDark, fontSize: 14),
                  dropdownColor: _C.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: _C.primaryLight),
                  decoration: _dropDeco('Barangay *', Icons.map_rounded),
                  items: lacarlotaBarangays
                      .map((b) => DropdownMenuItem<int>(
                            value: b.barangayId,
                            child: Text(b.name),
                          ))
                      .toList(),
                  validator: (v) => v == null ? 'Barangay is required' : null,
                  onChanged: _onCurrentBarangayChanged,
                ),
                _gap,

                // Auto-filled locked fields
                _LockedFieldRow(
                  label: 'City',
                  value: _currentCityController.text.isNotEmpty
                      ? _currentCityController.text
                      : '—',
                  icon: Icons.location_city_rounded,
                ),
                _gap,
                _LockedFieldRow(
                  label: 'Province',
                  value: _currentProvinceController.text.isNotEmpty
                      ? _currentProvinceController.text
                      : '—',
                  icon: Icons.terrain_rounded,
                ),
                _gap,
                _LockedFieldRow(
                  label: 'Country',
                  value: _currentCountryController.text.isNotEmpty
                      ? _currentCountryController.text
                      : '—',
                  icon: Icons.public_rounded,
                ),
                _gap,
                _LockedFieldRow(
                  label: 'ZIP Code',
                  value: _currentZipController.text.isNotEmpty
                      ? _currentZipController.text
                      : '—',
                  icon: Icons.pin_rounded,
                ),

                // ══════════════════════════════════════════════
                //  SAME ADDRESS CHECKBOX
                // ══════════════════════════════════════════════
                const SizedBox(height: 20),
                _SameAddressToggle(
                  value: widget.student.sameAddress == 'yes',
                  onChanged: (val) {
                    setState(() {
                      widget.student.sameAddress = val ? 'yes' : 'no';
                      if (val) {
                        widget.student.permanentHouseNo =
                            widget.student.currentHouseNo;
                        widget.student.permanentStreet =
                            widget.student.currentStreet;
                        widget.student.permanentBarangayId =
                            widget.student.currentBarangayId;
                        widget.student.permanentCity =
                            widget.student.currentCity;
                        widget.student.permanentProvince =
                            widget.student.currentProvince;
                        widget.student.permanentCountry =
                            widget.student.currentCountry;
                        widget.student.permanentZip = widget.student.currentZip;
                        _permanentHouseNoController.text =
                            widget.student.currentHouseNo ?? '';
                        _permanentStreetController.text =
                            widget.student.currentStreet ?? '';
                      } else {
                        widget.student.permanentHouseNo = null;
                        widget.student.permanentStreet = null;
                        widget.student.permanentBarangayId = null;
                        widget.student.permanentCity = 'La Carlota City';
                        widget.student.permanentProvince = 'Negros Occidental';
                        widget.student.permanentCountry = 'Philippines';
                        widget.student.permanentZip = '6130';
                        _permanentHouseNoController.clear();
                        _permanentStreetController.clear();
                      }
                      _updateStudent();
                    });
                  },
                ),

                // ══════════════════════════════════════════════
                //  PERMANENT ADDRESS (only if different)
                // ══════════════════════════════════════════════
                if (widget.student.sameAddress != 'yes') ...[
                  _sectionGap,
                  const _SectionHeader(
                    title: 'Permanent Address',
                    icon: Icons.house_rounded,
                  ),
                  _sectionGap,
                  TextFormField(
                    controller: _permanentHouseNoController,
                    style: const TextStyle(color: _C.textDark, fontSize: 14),
                    decoration: _fieldDeco('House No. / Lot / Bldg.',
                        icon: Icons.home_rounded),
                    onChanged: (_) {
                      widget.student.permanentHouseNo =
                          _permanentHouseNoController.text;
                      _updateStudent();
                    },
                  ),
                  _gap,
                  TextFormField(
                    controller: _permanentStreetController,
                    style: const TextStyle(color: _C.textDark, fontSize: 14),
                    decoration:
                        _fieldDeco('Street', icon: Icons.signpost_rounded),
                    onChanged: (_) {
                      widget.student.permanentStreet =
                          _permanentStreetController.text;
                      _updateStudent();
                    },
                  ),
                  _gap,
                  DropdownButtonFormField<int>(
                    value: widget.student.permanentBarangayId,
                    style: const TextStyle(color: _C.textDark, fontSize: 14),
                    dropdownColor: _C.white,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _C.primaryLight),
                    decoration: _dropDeco('Barangay', Icons.map_rounded),
                    items: lacarlotaBarangays
                        .map((b) => DropdownMenuItem<int>(
                              value: b.barangayId,
                              child: Text(b.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          widget.student.permanentBarangayId = value;
                          final barangay = _getBarangayById(value);
                          if (barangay != null &&
                              barangay.city != null &&
                              barangay.city!.isNotEmpty) {
                            widget.student.permanentCity =
                                '${barangay.city} City';
                          }
                          _updateStudent();
                        });
                      }
                    },
                  ),
                  _gap,
                  _LockedFieldRow(
                    label: 'City',
                    value: widget.student.permanentCity ?? '—',
                    icon: Icons.location_city_rounded,
                  ),
                  _gap,
                  _LockedFieldRow(
                    label: 'Province',
                    value: widget.student.permanentProvince ?? '—',
                    icon: Icons.terrain_rounded,
                  ),
                  _gap,
                  _LockedFieldRow(
                    label: 'Country',
                    value: widget.student.permanentCountry ?? '—',
                    icon: Icons.public_rounded,
                  ),
                  _gap,
                  _LockedFieldRow(
                    label: 'ZIP Code',
                    value: widget.student.permanentZip ?? '—',
                    icon: Icons.pin_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Teacher Banner
// ─────────────────────────────────────────────────────────────
class _TeacherBanner extends StatelessWidget {
  final String barangayName;
  const _TeacherBanner({required this.barangayName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _C.primaryMid.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFBBDEFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_pin_circle_rounded,
                color: _C.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your assigned barangay',
                  style: TextStyle(
                      fontSize: 11,
                      color: _C.textLight,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  barangayName,
                  style: const TextStyle(
                      fontSize: 13.5,
                      color: _C.primary,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _C.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Assigned',
                style: TextStyle(
                    fontSize: 10.5,
                    color: _C.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Same Address Toggle
// ─────────────────────────────────────────────────────────────
class _SameAddressToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SameAddressToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFE3F2FD) : _C.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? _C.primaryMid : _C.sky200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: _C.primaryMid,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(color: _C.sky300, width: 1.8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Same as current address',
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _C.textDark),
                ),
                Text(
                  value
                      ? 'Permanent address has been copied from current'
                      : 'Tap to copy current address to permanent',
                  style: const TextStyle(fontSize: 11.5, color: _C.textLight),
                ),
              ],
            ),
          ),
          Icon(
            value
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: value ? _C.primaryMid : _C.sky300,
            size: 20,
          ),
        ],
      ),
    );
  }
}
