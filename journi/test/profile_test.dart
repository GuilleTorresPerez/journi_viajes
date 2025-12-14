import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/mi_perfil.dart';
import 'package:journi/domain/user.dart';

import 'trip_service_test.dart';

void main() {
  testWidgets("🧱 _buildDataRow renderiza correctamente ID, Email y Fecha",
      (WidgetTester tester) async {
    final fakeUser = User(
      id: "u100",
      name: "Paula",
      lastName: "Tester",
      email: "paula@test.com",
      createdAt: DateTime(2024, 01, 15),
      updatedAt: DateTime(2024, 01, 15),
      passwordHash: '',
      passwordSalt: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MiPerfil(
          sesionIniciada: true,
          viajes: const [],
          selectedIndex: 4,
          tripRepo: FakeTripRepository(),
          entryRepo: FakeEntryRepository(),
          tripService: makeTripService(
            FakeTripRepository(),
            FakeUserRepository(),
            FakeEntryRepository(),
            FakeGeocodingRepository(),
          ),
          entryService: makeEntryService(FakeEntryRepository()),
          userRepo: FakeUserRepository(),
          userService: makeUserService(FakeUserRepository()),
          currentUser: fakeUser,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 🔎 ID
    expect(find.byIcon(Icons.perm_identity), findsOneWidget);
    expect(find.text("ID"), findsOneWidget);
    expect(find.text("u100"), findsOneWidget);

    // 🔎 Email
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    expect(find.text("Email"), findsOneWidget);
    expect(find.text("paula@test.com"), findsOneWidget);

    // 🔎 Fecha
    expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    expect(find.text("Usuario desde"), findsOneWidget);
    expect(find.text("2024-01-15"), findsOneWidget);
  });
}
