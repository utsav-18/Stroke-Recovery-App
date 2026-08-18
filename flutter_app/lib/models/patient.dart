class Patient {
  const Patient({
    required this.id,
    required this.userId,
    required this.patientCode,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
  });

  final int id;
  final int userId;
  final String patientCode;
  final String name;
  final String dateOfBirth;
  final String gender;
  final String phone;

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      patientCode: json['patient_code'] as String? ?? 'PT-0000',
      name: json['name'] as String? ?? 'Patient',
      dateOfBirth: json['date_of_birth'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Not provided',
      phone: json['phone'] as String? ?? '',
    );
  }
}
