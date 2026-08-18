class Doctor {
  const Doctor({
    required this.id,
    required this.userId,
    required this.doctorCode,
    required this.name,
    required this.specialization,
    required this.phone,
  });

  final int id;
  final int userId;
  final String doctorCode;
  final String name;
  final String specialization;
  final String phone;

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      doctorCode: json['doctor_code'] as String? ?? 'DOC-0000',
      name: json['name'] as String? ?? 'Doctor',
      specialization: json['specialization'] as String? ?? 'General Care',
      phone: json['phone'] as String? ?? '',
    );
  }
}
