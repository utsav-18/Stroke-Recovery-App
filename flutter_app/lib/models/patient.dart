class Patient {
  const Patient({
    required this.id,
    required this.userId,
    required this.patientCode,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
    this.assignedLevel = 1,
    this.gameStatus = 'IDLE',
  });

  final int id;
  final int userId;
  final String patientCode;
  final String name;
  final String dateOfBirth;
  final String gender;
  final String phone;
  final int assignedLevel;
  final String gameStatus;

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      patientCode: json['patient_code'] as String? ?? 'PT-0000',
      name: json['name'] as String? ?? 'Patient',
      dateOfBirth: json['date_of_birth'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Not provided',
      phone: json['phone'] as String? ?? '',
      assignedLevel: json['assigned_level'] as int? ?? 1,
      gameStatus: json['game_status'] as String? ?? 'IDLE',
    );
  }
}
