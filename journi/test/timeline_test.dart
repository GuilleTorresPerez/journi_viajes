import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/estadisticasScreen.dart';
import 'package:journi/map_screen.dart'; // ajusta si TimelineList está en otro archivo

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Datos de prueba usando Entry.create
  late List<Entry> entries;

  setUp(() {
    entries = [
      Entry.create(
        id: '1',
        tripId: 'trip1',
        type: EntryType.note,
        text: 'Primera nota',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ).valueOrNull!,
      Entry.create(
        id: '2',
        tripId: 'trip1',
        type: EntryType.photo,
        mediaUri: 'foto.jpg',
        createdAt: DateTime(2024, 1, 2),
        updatedAt: DateTime(2024, 1, 2),
      ).valueOrNull!,
      Entry.create(
        id: '3',
        tripId: 'trip1',
        type: EntryType.video,
        mediaUri: 'video.mp4',
        createdAt: DateTime(2024, 1, 3),
        updatedAt: DateTime(2024, 1, 3),
      ).valueOrNull!,
    ];
  });

  Widget _wrapTimeline(List<Entry> entries, {void Function(Entry)? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: TimelineList(
          entries: entries,
          onTapEntry: onTap,
        ),
      ),
    );
  }

  group('TimelineList Tests', () {
    testWidgets('Muestra correctamente todos los entries', (tester) async {
      await tester.pumpWidget(_wrapTimeline(entries));

      await tester.pumpAndSettle();

      expect(find.byType(TimelineTile), findsNWidgets(entries.length));

      for (final e in entries) {
        final text = e.text ?? (e.type == EntryType.photo
            ? 'Fotografía'
            : e.type == EntryType.video
            ? 'Vídeo'
            : 'Nota');
        expect(find.text(text), findsOneWidget);
      }

      // Comprobar iconos
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      expect(find.byIcon(Icons.photo), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });

    testWidgets('onTapEntry se dispara correctamente', (tester) async {
      Entry? tappedEntry;

      await tester.pumpWidget(_wrapTimeline(entries, onTap: (e) => tappedEntry = e));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Primera nota'));
      await tester.pumpAndSettle();

      expect(tappedEntry, equals(entries.first));

      await tester.tap(find.text('Fotografía'));
      await tester.pumpAndSettle();

      expect(tappedEntry, equals(entries[1]));
    });
  });
}
