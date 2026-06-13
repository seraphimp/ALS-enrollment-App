import 'package:flutter/material.dart';
import '../models/student_model.dart';

const _primary = Color(0xFF1565C0);
const _primaryLight = Color(0xFF1E9AFF);
const _bg = Color(0xFFF0F6FF);
const _surface = Colors.white;
const _border = Color(0xFFBBDEFB);
const _textPrimary = Color(0xFF0D1B2A);
const _textSecondary = Color(0xFF546E7A);

// ── Full decoration (with optional prefix icon) ── used for full-width fields
InputDecoration _inputDec(String label, {String? hint, IconData? icon}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
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

// ── Compact decoration ── NO prefixIcon, used inside Row() to prevent overflow
InputDecoration _compactDec(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textSecondary, fontSize: 13),
      filled: true,
      fillColor: _surface,
      isDense: true,
      // Extra left padding compensates for missing icon so text doesn't crowd the edge
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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

Widget _gap([double h = 14]) => SizedBox(height: h);

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
                  fontSize: 16, fontWeight: FontWeight.w700, color: _primary)),
        ],
      ),
    );

// ── Full-width dropdown (keeps prefixIcon) ────────────────────────────────────
DropdownButtonFormField<String> _dropdown({
  required String label,
  required String? value,
  required List<DropdownMenuItem<String>> items,
  required void Function(String?) onChanged,
  IconData? icon,
}) =>
    DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDec(label, icon: icon),
      dropdownColor: _surface,
      isExpanded: true,
      style: const TextStyle(color: _textPrimary, fontSize: 14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _primaryLight, size: 20),
      items: items,
      onChanged: onChanged,
    );

// ── Compact dropdown for use inside Row() ── NO prefixIcon ────────────────────
DropdownButtonFormField<String> _compactDropdown({
  required String label,
  required String? value,
  required List<DropdownMenuItem<String>> items,
  required void Function(String?) onChanged,
}) =>
    DropdownButtonFormField<String>(
      value: value,
      decoration: _compactDec(label),
      dropdownColor: _surface,
      isExpanded: true, // ← prevents internal text overflow
      style: const TextStyle(color: _textPrimary, fontSize: 13.5),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _primaryLight, size: 18),
      items: items,
      onChanged: onChanged,
    );

// ─────────────────────────────────────────────────────────────────────────────

class EducationTab extends StatefulWidget {
  final Student student;
  final Function(Student) onStudentUpdated;

  const EducationTab(
      {super.key, required this.student, required this.onStudentUpdated});

  @override
  State<EducationTab> createState() => _EducationTabState();
}

class _EducationTabState extends State<EducationTab> {
  late TextEditingController _disabilityDetailsController;
  late TextEditingController _incompleteReasonController;

  @override
  void initState() {
    super.initState();
    _disabilityDetailsController =
        TextEditingController(text: widget.student.disabilityDetails);
    _incompleteReasonController =
        TextEditingController(text: widget.student.incompleteReason);
  }

  @override
  void dispose() {
    _disabilityDetailsController.dispose();
    _incompleteReasonController.dispose();
    super.dispose();
  }

  void _updateStudent() {
    widget.student.disabilityDetails = _disabilityDetailsController.text;
    widget.student.incompleteReason = _incompleteReasonController.text;
    widget.onStudentUpdated(widget.student);
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
            // ── PWD / Disability ────────────────────────────────────────
            _sectionHeader(
                'Disability Information', Icons.accessibility_new_rounded),
            _card(children: [
              Row(children: [
                Expanded(
                  child: _compactDropdown(
                    // ← compact, no icon
                    label: 'PWD Status',
                    value: widget.student.isPwd,
                    items: const [
                      DropdownMenuItem(value: 'no', child: Text('No')),
                      DropdownMenuItem(value: 'yes', child: Text('Yes')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => widget.student.isPwd = v);
                        _updateStudent();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _compactDropdown(
                    // ← compact, no icon
                    label: 'Has PWD ID',
                    value: widget.student.hasPwdId,
                    items: const [
                      DropdownMenuItem(value: 'no', child: Text('No')),
                      DropdownMenuItem(value: 'yes', child: Text('Yes')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => widget.student.hasPwdId = v);
                        _updateStudent();
                      }
                    },
                  ),
                ),
              ]),
              _gap(),
              TextFormField(
                controller: _disabilityDetailsController,
                decoration: _inputDec('Disability Details',
                    hint: 'Describe if applicable', icon: Icons.notes_rounded),
                maxLines: 3,
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                onChanged: (_) => _updateStudent(),
              ),
            ]),

            const SizedBox(height: 16),

            // ── Educational Background ──────────────────────────────────
            _sectionHeader('Educational Background', Icons.school_rounded),
            _card(children: [
              Row(children: [
                Expanded(
                  child: _compactDropdown(
                    // ← compact, no icon
                    label: 'Last Grade Level',
                    value: widget.student.lastGradeLevel,
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Select Level')),
                      DropdownMenuItem(value: 'Kinder', child: Text('Kinder')),
                      DropdownMenuItem(
                          value: 'Grade 1', child: Text('Grade 1')),
                      DropdownMenuItem(
                          value: 'Grade 2', child: Text('Grade 2')),
                      DropdownMenuItem(
                          value: 'Grade 3', child: Text('Grade 3')),
                      DropdownMenuItem(
                          value: 'Grade 4', child: Text('Grade 4')),
                      DropdownMenuItem(
                          value: 'Grade 5', child: Text('Grade 5')),
                      DropdownMenuItem(
                          value: 'Grade 6', child: Text('Grade 6')),
                      DropdownMenuItem(
                          value: 'Grade 7', child: Text('Grade 7')),
                      DropdownMenuItem(
                          value: 'Grade 8', child: Text('Grade 8')),
                      DropdownMenuItem(
                          value: 'Grade 9', child: Text('Grade 9')),
                      DropdownMenuItem(
                          value: 'Grade 10', child: Text('Grade 10')),
                      DropdownMenuItem(
                          value: 'Grade 11', child: Text('Grade 11')),
                      DropdownMenuItem(
                          value: 'Grade 12', child: Text('Grade 12')),
                      DropdownMenuItem(
                          value: 'College', child: Text('College')),
                    ],
                    onChanged: (v) {
                      setState(() => widget.student.lastGradeLevel = v);
                      _updateStudent();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _compactDropdown(
                    // ← compact, no icon
                    label: 'Attended ALS',
                    value: widget.student.attendedAlsBefore,
                    items: const [
                      DropdownMenuItem(value: 'no', child: Text('No')),
                      DropdownMenuItem(value: 'yes', child: Text('Yes')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => widget.student.attendedAlsBefore = v);
                        _updateStudent();
                      }
                    },
                  ),
                ),
              ]),
              _gap(),
              // Full-width — safe to keep icon
              _dropdown(
                label: 'Reason for Not Being in School',
                value: widget.student.reasonNotInSchool,
                icon: Icons.help_outline_rounded,
                items: const [
                  DropdownMenuItem(value: '', child: Text('Select Reason')),
                  DropdownMenuItem(
                      value: 'No school in barangay',
                      child: Text('No school in barangay')),
                  DropdownMenuItem(
                      value: 'School too far from home',
                      child: Text('School too far from home')),
                  DropdownMenuItem(
                      value: 'Needed to help family',
                      child: Text('Needed to help family')),
                  DropdownMenuItem(
                      value:
                          'Unable to pay for miscellaneous and other expenses',
                      child: Text('Unable to pay for expenses')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) {
                  setState(() => widget.student.reasonNotInSchool = v);
                  _updateStudent();
                },
              ),
              _gap(),
              TextFormField(
                controller: _incompleteReasonController,
                decoration: _inputDec('Reason for Not Completing',
                    icon: Icons.edit_note_rounded),
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                onChanged: (_) => _updateStudent(),
              ),
            ]),

            const SizedBox(height: 16),

            // ── ALS Program ─────────────────────────────────────────────
            _sectionHeader(
                'ALS Program Enrollment', Icons.auto_stories_rounded),
            _card(children: [
              Row(children: [
                Expanded(
                  child: _compactDropdown(
                    // ← compact, no icon
                    label: 'ALS Program',
                    value: widget.student.alsProgram,
                    items: const [
                      DropdownMenuItem(
                          value: '', child: Text('Select Program')),
                      DropdownMenuItem(
                          value: 'basic literacy',
                          child: Text('Basic Literacy')),
                      DropdownMenuItem(
                          value: 'a&e elementary',
                          child: Text('A&E Elementary')),
                      DropdownMenuItem(
                          value: 'a&e secondary', child: Text('A&E Secondary')),
                      DropdownMenuItem(
                          value: 'als-shs', child: Text('ALS-SHS')),
                    ],
                    onChanged: (v) {
                      setState(() => widget.student.alsProgram = v);
                      _updateStudent();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _compactDropdown(
                    // ← compact, no icon
                    label: 'Literacy Level',
                    value: widget.student.levelOfLiteracy,
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Select Level')),
                      DropdownMenuItem(value: 'Basic', child: Text('Basic')),
                      DropdownMenuItem(
                          value: 'Elementary', child: Text('Elementary')),
                      DropdownMenuItem(value: 'JHS', child: Text('JHS')),
                      DropdownMenuItem(value: 'SHS', child: Text('SHS')),
                      DropdownMenuItem(value: 'Infed', child: Text('Infed')),
                    ],
                    onChanged: (v) {
                      setState(() => widget.student.levelOfLiteracy = v);
                      _updateStudent();
                    },
                  ),
                ),
              ]),
            ]),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
