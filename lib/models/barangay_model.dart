class Barangay {
  final int barangayId;
  final String name;
  final String? city;
  final String status;

  Barangay({
    required this.barangayId,
    required this.name,
    this.city,
    this.status = 'active',
  });

  factory Barangay.fromJson(Map<String, dynamic> json) {
    return Barangay(
      barangayId: json['barangay_id'],
      name: json['name'],
      city: json['city'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barangay_id': barangayId,
      'name': name,
      'city': city,
      'status': status,
    };
  }
}
