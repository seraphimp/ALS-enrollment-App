import 'package:flutter/material.dart';
import '../models/student_model.dart';

const _primary = Color(0xFF1565C0);
const _primaryLight = Color(0xFF1E9AFF);
const _bg = Color(0xFFF0F6FF);
const _surface = Colors.white;
const _border = Color(0xFFBBDEFB);
const _textPrimary = Color(0xFF0D1B2A);
const _textSecondary = Color(0xFF546E7A);

InputDecoration _inputDec(String label, {IconData? icon}) => InputDecoration(
      labelText: label,
      prefixIcon:
          icon != null ? Icon(icon, size: 18, color: _primaryLight) : null,
      labelStyle: const TextStyle(color: _textSecondary, fontSize: 14),
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
    );

Widget _gap() => const SizedBox(height: 14);

Widget _card({required List<Widget> children}) => Container(
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
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );

Widget _sectionHeader(String title, IconData icon, Color accent) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accent, _primary]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _primary)),
        ],
      ),
    );

// ──────────────────────────────────────────────────────────────────────────────

class ParentInfoTab extends StatefulWidget {
  final Student student;
  final Function(Student) onStudentUpdated;

  const ParentInfoTab(
      {super.key, required this.student, required this.onStudentUpdated});

  @override
  State<ParentInfoTab> createState() => _ParentInfoTabState();
}

class _ParentInfoTabState extends State<ParentInfoTab> {
  late TextEditingController _fatherLastNameController;
  late TextEditingController _fatherFirstNameController;
  late TextEditingController _fatherMiddleNameController;
  late TextEditingController _fatherOccupationController;
  late TextEditingController _motherLastNameController;
  late TextEditingController _motherFirstNameController;
  late TextEditingController _motherMiddleNameController;
  late TextEditingController _motherOccupationController;
  late TextEditingController _guardianLastNameController;
  late TextEditingController _guardianFirstNameController;
  late TextEditingController _guardianMiddleNameController;
  late TextEditingController _guardianOccupationController;

  @override
  void initState() {
    super.initState();
    _fatherLastNameController =
        TextEditingController(text: widget.student.fatherLastName);
    _fatherFirstNameController =
        TextEditingController(text: widget.student.fatherFirstName);
    _fatherMiddleNameController =
        TextEditingController(text: widget.student.fatherMiddleName);
    _fatherOccupationController =
        TextEditingController(text: widget.student.fatherOccupation);
    _motherLastNameController =
        TextEditingController(text: widget.student.motherLastName);
    _motherFirstNameController =
        TextEditingController(text: widget.student.motherFirstName);
    _motherMiddleNameController =
        TextEditingController(text: widget.student.motherMiddleName);
    _motherOccupationController =
        TextEditingController(text: widget.student.motherOccupation);
    _guardianLastNameController =
        TextEditingController(text: widget.student.guardianLastName);
    _guardianFirstNameController =
        TextEditingController(text: widget.student.guardianFirstName);
    _guardianMiddleNameController =
        TextEditingController(text: widget.student.guardianMiddleName);
    _guardianOccupationController =
        TextEditingController(text: widget.student.guardianOccupation);
  }

  @override
  void dispose() {
    _fatherLastNameController.dispose();
    _fatherFirstNameController.dispose();
    _fatherMiddleNameController.dispose();
    _fatherOccupationController.dispose();
    _motherLastNameController.dispose();
    _motherFirstNameController.dispose();
    _motherMiddleNameController.dispose();
    _motherOccupationController.dispose();
    _guardianLastNameController.dispose();
    _guardianFirstNameController.dispose();
    _guardianMiddleNameController.dispose();
    _guardianOccupationController.dispose();
    super.dispose();
  }

  void _updateStudent() {
    widget.student.fatherLastName = _fatherLastNameController.text;
    widget.student.fatherFirstName = _fatherFirstNameController.text;
    widget.student.fatherMiddleName = _fatherMiddleNameController.text;
    widget.student.fatherOccupation = _fatherOccupationController.text;
    widget.student.motherLastName = _motherLastNameController.text;
    widget.student.motherFirstName = _motherFirstNameController.text;
    widget.student.motherMiddleName = _motherMiddleNameController.text;
    widget.student.motherOccupation = _motherOccupationController.text;
    widget.student.guardianLastName = _guardianLastNameController.text;
    widget.student.guardianFirstName = _guardianFirstNameController.text;
    widget.student.guardianMiddleName = _guardianMiddleNameController.text;
    widget.student.guardianOccupation = _guardianOccupationController.text;
    widget.onStudentUpdated(widget.student);
  }

  List<Widget> _nameFields({
    required TextEditingController last,
    required TextEditingController first,
    required TextEditingController middle,
    required TextEditingController occupation,
  }) {
    return [
      Row(children: [
        Expanded(
            child: TextFormField(
                controller: last,
                decoration: _inputDec('Last Name', icon: Icons.badge_rounded),
                onChanged: (_) => _updateStudent())),
        const SizedBox(width: 10),
        Expanded(
            child: TextFormField(
                controller: first,
                decoration: _inputDec('First Name'),
                onChanged: (_) => _updateStudent())),
      ]),
      _gap(),
      Row(children: [
        Expanded(
            child: TextFormField(
                controller: middle,
                decoration: _inputDec('Middle Name'),
                onChanged: (_) => _updateStudent())),
        const SizedBox(width: 10),
        Expanded(
            child: TextFormField(
                controller: occupation,
                decoration: _inputDec('Occupation', icon: Icons.work_rounded),
                onChanged: (_) => _updateStudent())),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Father ─────────────────────────────────────────────────
            _sectionHeader("Father's Information", Icons.man_rounded,
                const Color(0xFF1E9AFF)),
            _card(
                children: _nameFields(
              last: _fatherLastNameController,
              first: _fatherFirstNameController,
              middle: _fatherMiddleNameController,
              occupation: _fatherOccupationController,
            )),

            const SizedBox(height: 16),

            // ── Mother ─────────────────────────────────────────────────
            _sectionHeader("Mother's Maiden Information", Icons.woman_rounded,
                const Color(0xFFEC407A)),
            _card(
                children: _nameFields(
              last: _motherLastNameController,
              first: _motherFirstNameController,
              middle: _motherMiddleNameController,
              occupation: _motherOccupationController,
            )),

            const SizedBox(height: 16),

            // ── Guardian ───────────────────────────────────────────────
            _sectionHeader("Guardian's Information",
                Icons.supervisor_account_rounded, const Color(0xFF00897B)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF00897B).withOpacity(0.30)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: Color(0xFF00897B)),
                    SizedBox(width: 8),
                    Text('Complete only if different from parents',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF00897B))),
                  ],
                ),
              ),
            ),
            _card(
                children: _nameFields(
              last: _guardianLastNameController,
              first: _guardianFirstNameController,
              middle: _guardianMiddleNameController,
              occupation: _guardianOccupationController,
            )),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
