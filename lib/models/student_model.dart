class Student {
  // Personal Information
  String? studentId;
  String? lrn;
  DateTime? enrollmentDate;
  String lastName;
  String firstName;
  String? middleName;
  String? extensionName;
  String? contactNumber;
  DateTime? birthdate;
  int? age;
  String sex;
  String? placeOfBirth;
  String? religion;
  String? motherTongue;
  String? indigenousCommunity;
  String fourPsBeneficiary;
  String? fourPsIdNumber;
  String civilStatus;

  // Address
  String? currentHouseNo;
  String? currentStreet;
  int? currentBarangayId;
  String currentCity;
  String currentProvince;
  String currentCountry;
  String currentZip;
  String sameAddress;
  String? permanentHouseNo;
  String? permanentStreet;
  int? permanentBarangayId;
  String permanentCity;
  String permanentProvince;
  String permanentCountry;
  String permanentZip;

  // Parents/Guardians
  String? fatherLastName;
  String? fatherFirstName;
  String? fatherMiddleName;
  String? fatherOccupation;
  String? motherLastName;
  String? motherFirstName;
  String? motherMiddleName;
  String? motherOccupation;
  String? guardianLastName;
  String? guardianFirstName;
  String? guardianMiddleName;
  String? guardianOccupation;

  // Disability
  String isPwd;
  String? disabilityDetails;
  String hasPwdId;

  // Education
  String? lastGradeLevel;
  String? reasonNotInSchool;
  String attendedAlsBefore;
  String? alsProgram;
  String? levelOfLiteracy;
  String? incompleteReason;

  // Accessibility
  String? distanceToClcKm;
  String? distanceToClcTime;
  String transportMode;
  String? transportModeOther;
  Map<String, String>? availabilitySchedule;

  // Learning Modalities
  String prefersBlended;
  String prefersHomeschooling;
  String prefersModularPrint;
  String prefersModularDigital;
  String prefersOnline;
  String prefersRadioTv;
  String prefersEduTv;

  String status;
  String? qrCode;

  Student({
    this.studentId,
    this.lrn,
    this.enrollmentDate,
    required this.lastName,
    required this.firstName,
    this.middleName,
    this.extensionName,
    this.contactNumber,
    this.birthdate,
    this.age,
    this.sex = 'male',
    this.placeOfBirth,
    this.religion,
    this.motherTongue,
    this.indigenousCommunity,
    this.fourPsBeneficiary = 'no',
    this.fourPsIdNumber,
    this.civilStatus = 'single',
    this.currentHouseNo,
    this.currentStreet,
    this.currentBarangayId,
    this.currentCity = 'La Carlota City',
    this.currentProvince = 'Negros Occidental',
    this.currentCountry = 'Philippines',
    this.currentZip = '6130',
    this.sameAddress = 'yes',
    this.permanentHouseNo,
    this.permanentStreet,
    this.permanentBarangayId,
    this.permanentCity = 'La Carlota City',
    this.permanentProvince = 'Negros Occidental',
    this.permanentCountry = 'Philippines',
    this.permanentZip = '6130',
    this.fatherLastName,
    this.fatherFirstName,
    this.fatherMiddleName,
    this.fatherOccupation,
    this.motherLastName,
    this.motherFirstName,
    this.motherMiddleName,
    this.motherOccupation,
    this.guardianLastName,
    this.guardianFirstName,
    this.guardianMiddleName,
    this.guardianOccupation,
    this.isPwd = 'no',
    this.disabilityDetails,
    this.hasPwdId = 'no',
    this.lastGradeLevel,
    this.reasonNotInSchool,
    this.attendedAlsBefore = 'no',
    this.alsProgram,
    this.levelOfLiteracy,
    this.incompleteReason,
    this.distanceToClcKm,
    this.distanceToClcTime,
    this.transportMode = 'walking',
    this.transportModeOther,
    this.availabilitySchedule,
    this.prefersBlended = 'no',
    this.prefersHomeschooling = 'no',
    this.prefersModularPrint = 'no',
    this.prefersModularDigital = 'no',
    this.prefersOnline = 'no',
    this.prefersRadioTv = 'no',
    this.prefersEduTv = 'no',
    this.status = 'enrolled',
  });

  

  Map<String, dynamic> toJson() {
    return {
      'lrn': lrn,
      'enrollment_date': enrollmentDate?.toIso8601String().split('T')[0],
      'last_name': lastName,
      'first_name': firstName,
      'middle_name': middleName,
      'extension_name': extensionName,
      'contact_number': contactNumber,
      'birthdate': birthdate?.toIso8601String().split('T')[0],
      'age': age,
      'sex': sex,
      'place_of_birth': placeOfBirth,
      'religion': religion,
      'mother_tongue': motherTongue,
      'indigenous_community': indigenousCommunity,
      'four_ps_beneficiary': fourPsBeneficiary,
      'four_ps_id_number': fourPsIdNumber,
      'civil_status': civilStatus,
      'current_house_no': currentHouseNo,
      'current_street': currentStreet,
      'current_barangay_id': currentBarangayId,
      'current_city': currentCity,
      'current_province': currentProvince,
      'current_country': currentCountry,
      'current_zip': currentZip,
      'same_address': sameAddress,
      'permanent_house_no': permanentHouseNo,
      'permanent_street': permanentStreet,
      'permanent_barangay_id': permanentBarangayId,
      'permanent_city': permanentCity,
      'permanent_province': permanentProvince,
      'permanent_country': permanentCountry,
      'permanent_zip': permanentZip,
      'father_last_name': fatherLastName,
      'father_first_name': fatherFirstName,
      'father_middle_name': fatherMiddleName,
      'father_occupation': fatherOccupation,
      'mother_last_name': motherLastName,
      'mother_first_name': motherFirstName,
      'mother_middle_name': motherMiddleName,
      'mother_occupation': motherOccupation,
      'guardian_last_name': guardianLastName,
      'guardian_first_name': guardianFirstName,
      'guardian_middle_name': guardianMiddleName,
      'guardian_occupation': guardianOccupation,
      'is_pwd': isPwd,
      'disability_details': disabilityDetails,
      'has_pwd_id': hasPwdId,
      'last_grade_level': lastGradeLevel,
      'reason_not_in_school': reasonNotInSchool,
      'attended_als_before': attendedAlsBefore,
      'als_program': alsProgram,
      'level_of_literacy': levelOfLiteracy,
      'incomplete_reason': incompleteReason,
      'distance_to_clc_km': distanceToClcKm,
      'distance_to_clc_time': distanceToClcTime,
      'transport_mode': transportMode,
      'transport_mode_other': transportModeOther,
      'availability_schedule':
          availabilitySchedule?.toString(),
      'prefers_blended': prefersBlended,
      'prefers_homeschooling': prefersHomeschooling,
      'prefers_modular_print': prefersModularPrint,
      'prefers_modular_digital': prefersModularDigital,
      'prefers_online': prefersOnline,
      'prefers_radio_tv': prefersRadioTv,
      'prefers_edu_tv': prefersEduTv,
      'status': status,
      'accept_terms': 'yes',
      'qr_code': qrCode,
    };
  }
}
