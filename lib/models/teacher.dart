  class Teacher {
    final int teacherId;
    final String firstName;
    final String lastName;
    final String? middleName;
    final String? email;
    final String? contactNumber;
    final int? barangayId;
    final String? barangayName;
    final String status;

    Teacher({
      required this.teacherId,
      required this.firstName,
      required this.lastName,
      this.middleName,
      this.email,
      this.contactNumber,
      this.barangayId,
      this.barangayName,
      this.status = 'active',
    });

    factory Teacher.fromJson(Map<String, dynamic> json) {
      // Helper functions for parsing
      int safeParseInt(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) {
          return int.tryParse(value) ?? 0;
        }
        return 0;
      }

      int? safeParseNullableInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is String) {
          return int.tryParse(value);
        }
        return null;
      }

      // Check if we need to parse full_name
      if (json['full_name'] != null &&
          (json['first_name'] == null || json['last_name'] == null)) {
        // Parse full_name into parts
        final fullName = json['full_name'].toString().trim();
        final parts = fullName.split(' ');

        String firstName = '';
        String lastName = '';
        String? middleName;

        if (parts.isEmpty) {
          firstName = '';
          lastName = '';
        } else if (parts.length == 1) {
          firstName = parts[0];
          lastName = '';
        } else if (parts.length == 2) {
          firstName = parts[0];
          lastName = parts[1];
        } else {
          firstName = parts[0];
          lastName = parts[parts.length - 1];
          middleName = parts.sublist(1, parts.length - 1).join(' ');
        }

        return Teacher(
          teacherId:
              safeParseInt(json['teacher_id'] ?? json['teacherId'] ?? json['id']),
          firstName: firstName,
          lastName: lastName,
          middleName: middleName,
          email: json['email'] ?? json['Email'] ?? json['EMAIL'],
          contactNumber: json['contact_number'] ??
              json['contactNumber'] ??
              json['phone'] ??
              json['Phone'],
          barangayId:
              safeParseNullableInt(json['barangay_id'] ?? json['barangayId']),
          barangayName:
              json['barangay_name'] ?? json['barangayName'] ?? json['barangay'],
          status: json['status'] ?? json['Status'] ?? 'active',
        );
      }

      // Use separate fields if available
      return Teacher(
        teacherId:
            safeParseInt(json['teacher_id'] ?? json['teacherId'] ?? json['id']),
        firstName:
            json['first_name'] ?? json['firstName'] ?? json['FirstName'] ?? '',
        lastName: json['last_name'] ?? json['lastName'] ?? json['LastName'] ?? '',
        middleName:
            json['middle_name'] ?? json['middleName'] ?? json['MiddleName'],
        email: json['email'] ?? json['Email'] ?? json['EMAIL'],
        contactNumber: json['contact_number'] ??
            json['contactNumber'] ??
            json['phone'] ??
            json['Phone'],
        barangayId:
            safeParseNullableInt(json['barangay_id'] ?? json['barangayId']),
        barangayName:
            json['barangay_name'] ?? json['barangayName'] ?? json['barangay'],
        status: json['status'] ?? json['Status'] ?? 'active',
      );
    }

    Map<String, dynamic> toJson() {
      return {
        'teacher_id': teacherId,
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'email': email,
        'contact_number': contactNumber,
        'barangay_id': barangayId,
        'barangay_name': barangayName,
        'status': status,
        'full_name': fullName,
      };
    }

    String get fullName {
      if (middleName != null && middleName!.isNotEmpty) {
        return '$firstName $middleName $lastName';
      }
      return '$firstName $lastName';
    }

    @override
    bool operator ==(Object other) =>
        identical(this, other) ||
        other is Teacher &&
            runtimeType == other.runtimeType &&
            teacherId == other.teacherId;

    @override
    int get hashCode => teacherId.hashCode;

    @override
    String toString() {
      return 'Teacher{id: $teacherId, name: $fullName, email: $email}';
    }
  }
