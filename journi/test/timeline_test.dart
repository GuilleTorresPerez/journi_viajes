import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/map_screen.dart';

void main() {
  Widget _wrap(Entry entry) {
    return MaterialApp(
      home: Scaffold(
        body: TimelineList(entries: [entry]),
      ),
    );
  }

  group('Unit tests - icon mapping', () {
    testWidgets('EntryType.note usa icono de nota', (tester) async {
      final entry = Entry.create(
        id: '1',
        tripId: 't',
        type: EntryType.note,
        text: 'Nota',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).valueOrNull!;

      await tester.pumpWidget(_wrap(entry));

      expect(find.byIcon(Icons.edit_note), findsOneWidget);
    });

    testWidgets('EntryType.photo usa icono de foto', (tester) async {
      final entry = Entry.create(
        id: '2',
        tripId: 't',
        type: EntryType.photo,
        mediaUri: 'foto.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).valueOrNull!;

      await tester.pumpWidget(_wrap(entry));

      expect(find.byIcon(Icons.photo), findsOneWidget);
    });
  });

  group('Unit tests - title mapping', () {
    testWidgets('Foto muestra texto "Fotografía"', (tester) async {
      final entry = Entry.create(
        id: '3',
        tripId: 't',
        type: EntryType.photo,
        mediaUri: 'foto.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).valueOrNull!;

      await tester.pumpWidget(_wrap(entry));

      expect(find.text('Fotografía'), findsOneWidget);
    });

    testWidgets('Vídeo muestra texto "Vídeo"', (tester) async {
      final entry = Entry.create(
        id: '4',
        tripId: 't',
        type: EntryType.video,
        mediaUri: 'video.mp4',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).valueOrNull!;

      await tester.pumpWidget(_wrap(entry));

      expect(find.text('Vídeo'), findsOneWidget);
    });
  });
}
