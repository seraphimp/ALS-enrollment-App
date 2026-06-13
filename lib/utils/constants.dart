class AppConstants {
  // App Info
  static const String appName = 'ALS Enrollment System';
  static const String appVersion = '1.0.0';

  // Colors
  static const int primaryColor = 0xFF0056B3;
  static const int secondaryColor = 0xFFFFCC00;
  static const int lightBlue = 0xFFE6F0FF;
  static const int darkBlue = 0xFF003D82;

  // Cities and ZIP codes
  static const Map<String, String> cityZipCodes = {
    'La Carlota': '6130',
    'San Enrique': '6104',
    'Bacolod City': '6100',
    'Bago City': '6101',
    'Cadiz City': '6121',
    'Escalante City': '6124',
    'Himamaylan City': '6108',
    'Kabankalan City': '6109',
    'La Castellana': '6131',
    'Manapla': '6120',
    'Pontevedra': '6105',
    'Pulupandan': '6102',
    'Sagay City': '6122',
    'San Carlos City': '6127',
    'Silay City': '6116',
    'Sipalay City': '6113',
    'Talisay City': '6115',
    'Toboso': '6125',
    'Valladolid': '6103',
    'Victorias City': '6119',
  };

  // Default values
  static const String defaultProvince = 'Negros Occidental';
  static const String defaultCountry = 'Philippines';
  static const String defaultCity = 'La Carlota City';
  static const String defaultZip = '6130';

  // Validation
  static const int minAge = 6;
  static const int maxAge = 100;
  static const int phoneNumberLength = 11;
}

class ValidationUtils {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final phoneRegex = RegExp(r'^(09|\+639)\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Invalid phone number format';
    }
    return null;
  }

  static String? validateAge(int? age) {
    if (age == null) {
      return 'Age is required';
    }
    if (age < AppConstants.minAge || age > AppConstants.maxAge) {
      return 'Age must be between ${AppConstants.minAge} and ${AppConstants.maxAge}';
    }
    return null;
  }
}

class DateUtils {
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static int calculateAge(DateTime birthdate) {
    final today = DateTime.now();
    int age = today.year - birthdate.year;
    if (today.month < birthdate.month ||
        (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    return age;
  }
}
