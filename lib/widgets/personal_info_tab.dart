import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _primary = Color(0xFF1565C0);
const _primaryLight = Color(0xFF1E9AFF);
const _bg = Color(0xFFF0F6FF);
const _surface = Colors.white;
const _surfaceBlue = Color(0xFFE3F2FD);
const _border = Color(0xFFBBDEFB);
const _textPrimary = Color(0xFF0D1B2A);
const _textSecondary = Color(0xFF546E7A);

InputDecoration _inputDec(String label, {String? hint, IconData? icon}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
          icon != null ? Icon(icon, size: 18, color: _primaryLight) : null,
      labelStyle: const TextStyle(color: _textSecondary, fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryLight, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2)),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3F2FD), width: 1.5)),
    );

Widget _sectionHeader(String title, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_primaryLight, _primary]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _primary,
              )),
        ],
      ),
    );

Widget _fieldGap() => const SizedBox(height: 14);

// ──────────────────────────────────────────────────────────────────────────────

class PersonalInfoTab extends StatefulWidget {
  final Student student;
  final Function(Student) onStudentUpdated;

  const PersonalInfoTab({
    super.key,
    required this.student,
    required this.onStudentUpdated,
  });

  @override
  State<PersonalInfoTab> createState() => _PersonalInfoTabState();
}

class _PersonalInfoTabState extends State<PersonalInfoTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _lrnController;
  late TextEditingController _lastNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _extensionNameController;
  late TextEditingController _contactNumberController;
  late TextEditingController _ageController;
  late TextEditingController _placeOfBirthController;
  late TextEditingController _religionController;
  late TextEditingController _motherTongueController;
  late TextEditingController _indigenousCommunityController;
  late TextEditingController _fourPsIdController;

  @override
  void initState() {
    super.initState();
    _lrnController = TextEditingController(text: widget.student.lrn);
    _lastNameController = TextEditingController(text: widget.student.lastName);
    _firstNameController =
        TextEditingController(text: widget.student.firstName);
    _middleNameController =
        TextEditingController(text: widget.student.middleName);
    _extensionNameController =
        TextEditingController(text: widget.student.extensionName);
    _contactNumberController =
        TextEditingController(text: widget.student.contactNumber);
    _ageController =
        TextEditingController(text: widget.student.age?.toString() ?? '');
    _placeOfBirthController =
        TextEditingController(text: widget.student.placeOfBirth);
    _religionController = TextEditingController(text: widget.student.religion);
    _motherTongueController =
        TextEditingController(text: widget.student.motherTongue);
    _indigenousCommunityController =
        TextEditingController(text: widget.student.indigenousCommunity);
    _fourPsIdController =
        TextEditingController(text: widget.student.fourPsIdNumber);
  }

  @override
  void dispose() {
    _lrnController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _extensionNameController.dispose();
    _contactNumberController.dispose();
    _ageController.dispose();
    _placeOfBirthController.dispose();
    _religionController.dispose();
    _motherTongueController.dispose();
    _indigenousCommunityController.dispose();
    _fourPsIdController.dispose();
    super.dispose();
  }

  void _updateStudent() {
    widget.student.lrn =
        _lrnController.text.isNotEmpty ? _lrnController.text : null;
    widget.student.lastName = _lastNameController.text;
    widget.student.firstName = _firstNameController.text;
    widget.student.middleName = _middleNameController.text.isNotEmpty
        ? _middleNameController.text
        : null;
    widget.student.extensionName = _extensionNameController.text.isNotEmpty
        ? _extensionNameController.text
        : null;
    widget.student.contactNumber = _contactNumberController.text.isNotEmpty
        ? _contactNumberController.text
        : null;
    widget.student.placeOfBirth = _placeOfBirthController.text.isNotEmpty
        ? _placeOfBirthController.text
        : null;
    widget.student.religion =
        _religionController.text.isNotEmpty ? _religionController.text : null;
    widget.student.motherTongue = _motherTongueController.text.isNotEmpty
        ? _motherTongueController.text
        : null;
    widget.student.indigenousCommunity =
        _indigenousCommunityController.text.isNotEmpty
            ? _indigenousCommunityController.text
            : null;
    widget.student.fourPsIdNumber =
        _fourPsIdController.text.isNotEmpty ? _fourPsIdController.text : null;
    if (_ageController.text.isNotEmpty) {
      widget.student.age = int.tryParse(_ageController.text);
    } else {
      widget.student.age = null;
    }
    widget.onStudentUpdated(widget.student);
  }

  void _calculateAge(DateTime birthdate) {
    final today = DateTime.now();
    int age = today.year - birthdate.year;
    if (today.month < birthdate.month ||
        (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    setState(() {
      _ageController.text = age.toString();
      widget.student.age = age;
    });
    _updateStudent();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.student.birthdate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primaryLight,
            onPrimary: Colors.white,
            surface: _surface,
            onSurface: _textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        widget.student.birthdate = picked;
        _calculateAge(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section: Personal Details ──────────────────────────────
              _sectionHeader('Personal Details', Icons.person_rounded),
              _card(children: [
                TextFormField(
                  controller: _lrnController,
                  decoration: _inputDec('Learner Reference No. (LRN)',
                      hint: 'Optional', icon: Icons.numbers_rounded),
                  onChanged: (_) => _updateStudent(),
                ),
                _fieldGap(),
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration:
                          _inputDec('Last Name *', icon: Icons.badge_rounded),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                      onChanged: (_) => _updateStudent(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: _inputDec('First Name *'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                      onChanged: (_) => _updateStudent(),
                    ),
                  ),
                ]),
                _fieldGap(),
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _middleNameController,
                      decoration: _inputDec('Middle Name'),
                      onChanged: (_) => _updateStudent(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _extensionNameController,
                      decoration: _inputDec('Ext. (Jr., III)'),
                      onChanged: (_) => _updateStudent(),
                    ),
                  ),
                ]),
              ]),

              const SizedBox(height: 16),

              // ── Section: Birth & Identity ──────────────────────────────
              _sectionHeader('Birth & Identity', Icons.cake_rounded),
              _card(children: [
                // Birthdate picker
                GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      readOnly: true,
                      decoration: _inputDec('Birth Date *',
                          hint: 'Tap to select',
                          icon: Icons.calendar_today_rounded),
                      controller: TextEditingController(
                        text: widget.student.birthdate != null
                            ? DateFormat('yyyy-MM-dd')
                                .format(widget.student.birthdate!)
                            : '',
                      ),
                    ),
                  ),
                ),
                _fieldGap(),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration:
                          _inputDec('Age', icon: Icons.person_outline_rounded),
                      enabled: false,
                      style: TextStyle(color: _textSecondary.withOpacity(0.8)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: widget.student.sex,
                      decoration: _inputDec('Sex'),
                      dropdownColor: _surface,
                      style: const TextStyle(color: _textPrimary, fontSize: 14),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'female', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => widget.student.sex = value);
                          _updateStudent();
                        }
                      },
                    ),
                  ),
                ]),
                _fieldGap(),
                DropdownButtonFormField<String>(
                  value: widget.student.civilStatus,
                  decoration:
                      _inputDec('Civil Status', icon: Icons.favorite_rounded),
                  dropdownColor: _surface,
                  style: const TextStyle(color: _textPrimary, fontSize: 14),
                  items: const [
                    DropdownMenuItem(value: 'single', child: Text('Single')),
                    DropdownMenuItem(value: 'married', child: Text('Married')),
                    DropdownMenuItem(
                        value: 'separated', child: Text('Separated')),
                    DropdownMenuItem(
                        value: 'widow/er', child: Text('Widow/Widower')),
                    DropdownMenuItem(
                        value: 'solo parent', child: Text('Solo Parent')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => widget.student.civilStatus = value);
                      _updateStudent();
                    }
                  },
                ),
                _fieldGap(),
                TextFormField(
                  controller: _placeOfBirthController,
                  decoration: _inputDec('Place of Birth',
                      icon: Icons.location_on_rounded),
                  onChanged: (_) => _updateStudent(),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Section: Contact ───────────────────────────────────────
              _sectionHeader('Contact & Background', Icons.phone_rounded),
              _card(children: [
                TextFormField(
                  controller: _contactNumberController,
                  decoration:
                      _inputDec('Contact Number', icon: Icons.phone_rounded),
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => _updateStudent(),
                ),
                _fieldGap(),
                TextFormField(
                  controller: _religionController,
                  decoration:
                      _inputDec('Religion', icon: Icons.brightness_5_rounded),
                  onChanged: (_) => _updateStudent(),
                ),
                _fieldGap(),
                TextFormField(
                  controller: _motherTongueController,
                  decoration:
                      _inputDec('Mother Tongue', icon: Icons.translate_rounded),
                  onChanged: (_) => _updateStudent(),
                ),
                _fieldGap(),
                TextFormField(
                  controller: _indigenousCommunityController,
                  decoration: _inputDec('Indigenous Community',
                      icon: Icons.groups_rounded),
                  onChanged: (_) => _updateStudent(),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Section: 4Ps ───────────────────────────────────────────
              _sectionHeader(
                  '4Ps Beneficiary', Icons.volunteer_activism_rounded),
              _card(children: [
                DropdownButtonFormField<String>(
                  value: widget.student.fourPsBeneficiary,
                  decoration: _inputDec('4Ps Beneficiary'),
                  dropdownColor: _surface,
                  style: const TextStyle(color: _textPrimary, fontSize: 14),
                  items: const [
                    DropdownMenuItem(value: 'no', child: Text('No')),
                    DropdownMenuItem(value: 'yes', child: Text('Yes')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        widget.student.fourPsBeneficiary = value;
                        if (value == 'no') {
                          _fourPsIdController.clear();
                          widget.student.fourPsIdNumber = null;
                        }
                      });
                      _updateStudent();
                    }
                  },
                ),
                if (widget.student.fourPsBeneficiary == 'yes') ...[
                  _fieldGap(),
                  TextFormField(
                    controller: _fourPsIdController,
                    decoration: _inputDec('4Ps ID Number',
                        icon: Icons.credit_card_rounded),
                    onChanged: (_) => _updateStudent(),
                  ),
                ],
              ]),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _card({required List<Widget> children}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1E9AFF).withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}
