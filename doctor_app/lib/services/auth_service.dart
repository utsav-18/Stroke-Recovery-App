import '../models/user.dart';

class AuthService {
  const AuthService();

  Future<UserModel> login({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw Exception('Missing email or password.');
    }

    return UserModel(
      id: 1,
      email: normalizedEmail,
      role: 'PATIENT',
      name: 'Mia Chen',
    );
  }

  Future<UserModel> register({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw Exception('Missing email or password.');
    }

    return UserModel(
      id: 2,
      email: normalizedEmail,
      role: 'PATIENT',
      name: 'New Patient',
    );
  }

  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<UserModel?> currentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const UserModel(
      id: 1,
      email: 'mia.chen@rehabtrack.dev',
      role: 'PATIENT',
      name: 'Mia Chen',
    );
  }
}
