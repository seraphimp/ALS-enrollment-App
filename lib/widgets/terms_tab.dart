import 'package:flutter/material.dart';

const _primary = Color(0xFF1565C0);
const _primaryLight = Color(0xFF1E9AFF);
const _bg = Color(0xFFF0F6FF);
const _surface = Colors.white;
const _border = Color(0xFFBBDEFB);
const _textPrimary = Color(0xFF0D1B2A);
const _textSecondary = Color(0xFF546E7A);

class TermsTab extends StatelessWidget {
  final bool termsAccepted;
  final Function(bool) onTermsChanged;

  const TermsTab(
      {super.key, required this.termsAccepted, required this.onTermsChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: [_primaryLight, _primary]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.gavel_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Terms and Conditions',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _primary)),
              ],
            ),
            const SizedBox(height: 16),

            // Terms document card
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF1E9AFF).withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  // Document header stripe
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF1E9AFF)]),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.description_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ALS Enrollment Agreement — La Carlota City Division',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Terms body
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'By enrolling in the Alternative Learning System (ALS) of La Carlota City Division, you agree to the following terms and conditions:',
                          style: TextStyle(
                              fontSize: 13, color: _textSecondary, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        _termsSection('1. Enrollment Requirements', [
                          'All information provided during enrollment must be accurate and complete.',
                          'Required documents must be submitted as requested by the ALS center.',
                          'False information may result in enrollment cancellation.',
                        ]),
                        _termsSection('2. Learner Responsibilities', [
                          'Regular attendance in learning sessions as scheduled.',
                          'Active participation in all learning activities.',
                          'Completion of assigned modules and assessments.',
                          'Respect for teachers, staff, and fellow learners.',
                        ]),
                        _termsSection('3. Learning Modalities', [
                          'Learners may be assigned to various learning modalities based on availability and assessment.',
                          'Modalities include face-to-face, modular, blended, and online learning.',
                          'The ALS center reserves the right to adjust learning modalities as needed.',
                        ]),
                        _termsSection('4. Data Privacy', [
                          'Personal information will be collected and stored in accordance with the Data Privacy Act of 2012.',
                          'Information will be used for educational and reporting purposes only.',
                          'Learners have the right to access and correct their personal information.',
                        ]),
                        _termsSection('5. Assessment and Certification', [
                          'Regular assessments will be conducted to monitor progress.',
                          'Completion certificates will be issued upon meeting all requirements.',
                          'The ALS Accreditation and Equivalency (A&E) test is optional.',
                        ]),
                        _termsSection('6. Code of Conduct', [
                          'Maintain proper decorum during learning sessions.',
                          'Respect cultural and religious diversity.',
                          'Prohibition of any form of harassment or discrimination.',
                          'Compliance with ALS center rules and regulations.',
                        ]),
                        _termsSection('7. Health and Safety', [
                          'Compliance with health protocols during face-to-face sessions.',
                          'Reporting of any health concerns to ALS facilitators.',
                          'Maintenance of clean and safe learning environment.',
                        ]),
                        _termsSection('8. Withdrawal Policy', [
                          'Learners may withdraw from the program with proper notification.',
                          'Re-enrollment may be subject to availability.',
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Acceptance card
            GestureDetector(
              onTap: () => onTermsChanged(!termsAccepted),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: termsAccepted ? const Color(0xFFE3F2FD) : _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: termsAccepted
                        ? _primaryLight.withOpacity(0.60)
                        : _border,
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: termsAccepted
                          ? _primaryLight.withOpacity(0.12)
                          : Colors.transparent,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            termsAccepted ? _primaryLight : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: termsAccepted ? _primaryLight : _border,
                          width: 2,
                        ),
                      ),
                      child: termsAccepted
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I have read, understood, and agree to the Terms and Conditions of the Alternative Learning System program. *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: termsAccepted ? _primary : _textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Warning banner when not accepted
            if (!termsAccepted) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.50)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Color(0xFFF59E0B), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please review and accept the Terms and Conditions before submitting enrollment.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8D6E00),
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _termsSection(String title, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _primary,
              )),
          const SizedBox(height: 6),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: const BoxDecoration(
                        color: _primaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(p,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                            height: 1.5,
                          )),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
