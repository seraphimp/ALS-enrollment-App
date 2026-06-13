import 'package:flutter/material.dart';
import '../models/student_model.dart';

const _primary = Color(0xFF1565C0);
const _primaryLight = Color(0xFF1E9AFF);
const _bg = Color(0xFFF0F6FF);
const _surface = Colors.white;
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

// ──────────────────────────────────────────────────────────────────────────────

class AccessibilityTab extends StatefulWidget {
  final Student student;
  final Function(Student) onStudentUpdated;

  const AccessibilityTab(
      {super.key, required this.student, required this.onStudentUpdated});

  @override
  State<AccessibilityTab> createState() => _AccessibilityTabState();
}

class _AccessibilityTabState extends State<AccessibilityTab> {
  late TextEditingController _distanceKmController;
  late TextEditingController _distanceTimeController;
  late TextEditingController _transportOtherController;

  final Map<String, TimeOfDay?> _schedule = {
    'monday': null,
    'tuesday': null,
    'wednesday': null,
    'thursday': null,
    'friday': null,
    'saturday': null,
    'sunday': null,
  };

  final List<_ModalityItem> _modalities = const [
    _ModalityItem('prefersBlended', 'Blended Learning', Icons.devices_rounded),
    _ModalityItem('prefersHomeschooling', 'Homeschooling', Icons.home_rounded),
    _ModalityItem(
        'prefersModularPrint', 'Modular (Print)', Icons.menu_book_rounded),
    _ModalityItem(
        'prefersModularDigital', 'Modular (Digital)', Icons.tablet_mac_rounded),
    _ModalityItem('prefersOnline', 'Online Learning', Icons.wifi_rounded),
    _ModalityItem(
        'prefersRadioTv', 'Radio/TV-Based Instruction', Icons.tv_rounded),
    _ModalityItem(
        'prefersEduTv', 'Educational TV', Icons.ondemand_video_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _distanceKmController =
        TextEditingController(text: widget.student.distanceToClcKm);
    _distanceTimeController =
        TextEditingController(text: widget.student.distanceToClcTime);
    _transportOtherController =
        TextEditingController(text: widget.student.transportModeOther);

    if (widget.student.availabilitySchedule != null) {
      widget.student.availabilitySchedule!.forEach((key, value) {
        if (value.isNotEmpty) {
          final parts = value.split(':');
          if (parts.length == 2) {
            _schedule[key] = TimeOfDay(
                hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _distanceKmController.dispose();
    _distanceTimeController.dispose();
    _transportOtherController.dispose();
    super.dispose();
  }

  void _updateStudent() {
    widget.student.distanceToClcKm = _distanceKmController.text;
    widget.student.distanceToClcTime = _distanceTimeController.text;
    widget.student.transportModeOther = _transportOtherController.text;

    final scheduleMap = <String, String>{};
    _schedule.forEach((day, time) {
      if (time != null) {
        scheduleMap[day] =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
    });
    widget.student.availabilitySchedule = scheduleMap;
    widget.onStudentUpdated(widget.student);
  }

  Future<void> _selectTime(String day) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _schedule[day] ?? TimeOfDay.now(),
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
        _schedule[day] = picked;
        _updateStudent();
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Tap to set';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool _getModalityValue(String key) {
    switch (key) {
      case 'prefersBlended':
        return widget.student.prefersBlended == 'yes';
      case 'prefersHomeschooling':
        return widget.student.prefersHomeschooling == 'yes';
      case 'prefersModularPrint':
        return widget.student.prefersModularPrint == 'yes';
      case 'prefersModularDigital':
        return widget.student.prefersModularDigital == 'yes';
      case 'prefersOnline':
        return widget.student.prefersOnline == 'yes';
      case 'prefersRadioTv':
        return widget.student.prefersRadioTv == 'yes';
      case 'prefersEduTv':
        return widget.student.prefersEduTv == 'yes';
      default:
        return false;
    }
  }

  void _setModalityValue(String key, bool value) {
    final v = value ? 'yes' : 'no';
    switch (key) {
      case 'prefersBlended':
        widget.student.prefersBlended = v;
        break;
      case 'prefersHomeschooling':
        widget.student.prefersHomeschooling = v;
        break;
      case 'prefersModularPrint':
        widget.student.prefersModularPrint = v;
        break;
      case 'prefersModularDigital':
        widget.student.prefersModularDigital = v;
        break;
      case 'prefersOnline':
        widget.student.prefersOnline = v;
        break;
      case 'prefersRadioTv':
        widget.student.prefersRadioTv = v;
        break;
      case 'prefersEduTv':
        widget.student.prefersEduTv = v;
        break;
    }
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
            // ── Accessibility to CLC ────────────────────────────────────
            _sectionHeader('Accessibility to CLC', Icons.directions_rounded),
            _card(children: [
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _distanceKmController,
                    decoration: _inputDec('Distance (km)',
                        icon: Icons.social_distance_rounded),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateStudent(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _distanceTimeController,
                    decoration: _inputDec('Travel Time (min)',
                        icon: Icons.timer_rounded),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateStudent(),
                  ),
                ),
              ]),
              _gap(),
              DropdownButtonFormField<String>(
                value: widget.student.transportMode,
                decoration: _inputDec('Mode of Transportation',
                    icon: Icons.directions_bus_rounded),
                dropdownColor: _surface,
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 'walking', child: Text('🚶 Walking')),
                  DropdownMenuItem(
                      value: 'motorcycle', child: Text('🏍 Motorcycle')),
                  DropdownMenuItem(value: 'bicycle', child: Text('🚲 Bicycle')),
                  DropdownMenuItem(value: 'others', child: Text('🚌 Others')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => widget.student.transportMode = v);
                    _updateStudent();
                  }
                },
              ),
              if (widget.student.transportMode == 'others') ...[
                _gap(),
                TextFormField(
                  controller: _transportOtherController,
                  decoration: _inputDec('Specify Transportation',
                      icon: Icons.edit_rounded),
                  onChanged: (_) => _updateStudent(),
                ),
              ],
            ]),

            const SizedBox(height: 16),

            // ── Schedule ────────────────────────────────────────────────
            _sectionHeader(
                'Preferred Learning Schedule', Icons.calendar_month_rounded),
            _card(children: [
              ..._schedule.keys.map((day) {
                final isSet = _schedule[day] != null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      // Day label
                      SizedBox(
                        width: 90,
                        child: Text(
                          day[0].toUpperCase() + day.substring(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ),

                      // Time picker button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(day),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: isSet
                                  ? _primaryLight.withOpacity(0.08)
                                  : _surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSet
                                    ? _primaryLight.withOpacity(0.50)
                                    : _border,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: isSet
                                      ? _primaryLight
                                      : const Color(0xFFB0BEC5),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(_schedule[day]),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSet
                                        ? _primary
                                        : const Color(0xFFB0BEC5),
                                    fontWeight: isSet
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Clear button
                      if (isSet)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _schedule[day] = null;
                                _updateStudent();
                              });
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: Color(0xFFEF5350)),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ]),

            const SizedBox(height: 16),

            // ── Modalities ──────────────────────────────────────────────
            _sectionHeader(
                'Preferred Learning Modalities', Icons.layers_rounded),
            _card(children: [
              ..._modalities.map((m) {
                final isSelected = _getModalityValue(m.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _setModalityValue(m.key, !isSelected);
                        _updateStudent();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _primaryLight.withOpacity(0.10)
                            : _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _primaryLight.withOpacity(0.60)
                              : _border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryLight.withOpacity(0.15)
                                  : const Color(0xFFF5F9FF),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(m.icon,
                                size: 17,
                                color: isSelected
                                    ? _primaryLight
                                    : const Color(0xFFB0BEC5)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              m.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected ? _primary : _textPrimary,
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryLight
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? _primaryLight : _border,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ]),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ModalityItem {
  final String key;
  final String label;
  final IconData icon;
  const _ModalityItem(this.key, this.label, this.icon);
}
