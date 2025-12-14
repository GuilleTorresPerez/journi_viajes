import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/mi_perfil.dart';
import 'package:journi/domain/user.dart';

import 'trip_service_test.dart';

void main() {
  testWidgets("🧱 _buildDataRow muestra icono, título y valor correctamente",
      (WidgetTester tester) async {
    // Usuario mínimo fake (no se usa realmente aquí)
    final fakeUser = User(
      id: "u1",
      name: "Test",
      lastName: "User",
      email: "test@test.com",
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      passwordHash: '',
      passwordSalt: '',
    );

    // Construimos el widget padre
    final widget = MiPerfil(
      sesionIniciada: true,
      viajes: const [],
      selectedIndex: 4,
      tripRepo: FakeTripRepository(),
      entryRepo: FakeEntryRepository(),
      tripService: makeTripService(FakeTripRepository(), FakeUserRepository(),
          FakeEntryRepository(), FakeGeocodingRepository()),
      entryService: makeEntryService(FakeEntryRepository()),
      userRepo: FakeUserRepository(),
      userService: makeUserService(FakeUserRepository()),
      currentUser: fakeUser,
    );

    // Accedemos al State
    final state = widget.createState() as dynamic;

    // Widget a testear
    final dataRow = state._buildDataRow(
      Icons.email,
      "Email",
      "correo@test.com",
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: dataRow),
      ),
    );

    // 🔎 Icono
    expect(find.byIcon(Icons.email), findsOneWidget);

    // 🔎 Título
    expect(find.text("Email"), findsOneWidget);

    // 🔎 Valor
    expect(find.text("correo@test.com"), findsOneWidget);
  });
}
