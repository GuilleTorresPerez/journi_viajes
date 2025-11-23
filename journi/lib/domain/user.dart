import 'package:journi/application/shared/result.dart';

class User {
  final String id;
  final String name;
  final String lastName;
  final String email; // siempre en lowercase
  final String passwordHash; // nunca guardes la contraseña en claro
  final String passwordSalt; // base64
  final DateTime createdAt; // UTC
  final DateTime updatedAt; // UTC

  const User({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.createdAt,
    required this.updatedAt,
  });

  static Result<User> create({
    required String id,
    required String name,
    required String lastName,
    required String email,
    required String passwordHash,
    required String passwordSalt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final errs = <ValidationError>[];

    if (id.trim().isEmpty) errs.add(const ValidationError('id vacío'));
    if (name.trim().isEmpty) errs.add(const ValidationError('name vacío'));
    if (lastName.trim().isEmpty)
      errs.add(const ValidationError('lastName vacío'));

    final e = email.trim().toLowerCase();
    final emailRx = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRx.hasMatch(e)) errs.add(const ValidationError('email inválido'));

    if (passwordHash.isEmpty || passwordSalt.isEmpty) {
      errs.add(const ValidationError('password hash/salt requeridos'));
    }
    if (updatedAt.isBefore(createdAt)) {
      errs.add(const ValidationError('updatedAt < createdAt'));
    }
    if (errs.isNotEmpty) return Err<User>(errs);

    return Ok(
      User(
        id: id.trim(),
        name: name.trim(),
        lastName: lastName.trim(),
        email: e,
        passwordHash: passwordHash,
        passwordSalt: passwordSalt,
        createdAt: createdAt.toUtc(),
        updatedAt: updatedAt.toUtc(),
      ),
    );
  }
}
