import '../models/analyze_result.dart';
import '../models/doctor.dart';
import '../models/exercise_session.dart';
import '../models/patient.dart';
import '../models/progress.dart';
import '../models/user.dart';

class MockDataService {
  const MockDataService();

  UserModel get currentUser => const UserModel(
        id: 1,
        email: 'mia.chen@rehabtrack.dev',
        role: 'PATIENT',
        name: 'Mia Chen',
      );

  List<Patient> get patients => const [
    Patient(
      id: 1,
      userId: 3,
      patientCode: 'PT-2001',
      name: 'Mia Chen',
      dateOfBirth: '1991-04-18',
      gender: 'Female',
      phone: '+1 (415) 555-0201',
    ),
    Patient(
      id: 2,
      userId: 4,
      patientCode: 'PT-2002',
      name: 'Omar Hassan',
      dateOfBirth: '1978-09-02',
      gender: 'Male',
      phone: '+1 (415) 555-0202',
    ),
    Patient(
      id: 3,
      userId: 5,
      patientCode: 'PT-2003',
      name: 'Nina Patel',
      dateOfBirth: '1986-12-11',
      gender: 'Female',
      phone: '+1 (415) 555-0203',
    ),
    Patient(
      id: 4,
      userId: 6,
      patientCode: 'PT-2004',
      name: 'Leo Martin',
      dateOfBirth: '1969-07-25',
      gender: 'Male',
      phone: '+1 (415) 555-0204',
    ),
    Patient(
      id: 5,
      userId: 7,
      patientCode: 'PT-2005',
      name: 'Alina Garcia',
      dateOfBirth: '1995-03-14',
      gender: 'Female',
      phone: '+1 (415) 555-0205',
    ),
  ];

  List<Doctor> get doctors => const [
    Doctor(
      id: 1,
      userId: 1,
      doctorCode: 'DOC-1001',
      name: 'Dr. Emma Smith',
      specialization: 'Neurological Rehabilitation',
      phone: '+1 (415) 555-0101',
    ),
    Doctor(
      id: 2,
      userId: 2,
      doctorCode: 'DOC-1002',
      name: 'Dr. Sofia Rivera',
      specialization: 'Mobility Therapy',
      phone: '+1 (415) 555-0102',
    ),
  ];

  List<ExerciseSession> get patientSessions => [
    ExerciseSession(
      id: 1,
      patientId: 1,
      exerciseType: 'Shoulder Flexion',
      startedAt: DateTime(2026, 7, 10, 9, 0),
      completedAt: DateTime(2026, 7, 10, 9, 6),
      movementStatus: 'Improving',
      confidenceScore: 0.82,
      emotion: 'Happy',
    ),
    ExerciseSession(
      id: 2,
      patientId: 1,
      exerciseType: 'Arm Reach',
      startedAt: DateTime(2026, 7, 14, 10, 15),
      completedAt: DateTime(2026, 7, 14, 10, 21),
      movementStatus: 'Improved',
      confidenceScore: 0.87,
      emotion: 'Calm',
    ),
    ExerciseSession(
      id: 3,
      patientId: 1,
      exerciseType: 'Grip Recovery',
      startedAt: DateTime(2026, 7, 18, 11, 30),
      completedAt: DateTime(2026, 7, 18, 11, 36),
      movementStatus: 'Improved',
      confidenceScore: 0.91,
      emotion: 'Happy',
    ),
  ];

  ProgressSummary get patientProgress => const ProgressSummary(
        patientId: 1,
        totalSessions: 3,
        averageConfidence: 0.87,
        latestMovementStatus: 'Improved',
        confidenceTrend: [0.72, 0.81, 0.87],
        movementHistory: [
          MovementTrendPoint(date: '2026-07-10', status: 'Improving'),
          MovementTrendPoint(date: '2026-07-14', status: 'Improved'),
          MovementTrendPoint(date: '2026-07-18', status: 'Improved'),
        ],
        emotionHistory: [
          EmotionTrendPoint(date: '2026-07-10', emotion: 'Happy'),
          EmotionTrendPoint(date: '2026-07-14', emotion: 'Calm'),
          EmotionTrendPoint(date: '2026-07-18', emotion: 'Happy'),
        ],
      );

  List<AnalyzeResult> get latestResults => const [
    AnalyzeResult(
      movementStatus: 'Improving',
      confidenceScore: 0.82,
      emotion: 'Happy',
    ),
    AnalyzeResult(
      movementStatus: 'Improved',
      confidenceScore: 0.87,
      emotion: 'Calm',
    ),
    AnalyzeResult(
      movementStatus: 'Improved',
      confidenceScore: 0.91,
      emotion: 'Happy',
    ),
  ];

  Future<AnalyzeResult> analyzeVideoMock() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return const AnalyzeResult(
      movementStatus: 'Improved',
      confidenceScore: 0.86,
      emotion: 'Happy',
    );
  }
}
