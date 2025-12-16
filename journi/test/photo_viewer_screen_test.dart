import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/PhotoViewerScreen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhotoViewerScreen', () {
    testWidgets(
      'muestra InteractiveViewer cuando el archivo existe',
      (WidgetTester tester) async {
        // 🔹 Crear archivo temporal vacío
        final tempDir = await Directory.systemTemp.createTemp();
        final file = File('${tempDir.path}/dummy.txt');
        await file.writeAsString('dummy');

        await tester.pumpWidget(
          MaterialApp(
            home: PhotoViewerScreen(uri: file.path),
          ),
        );

        // 🔹 No hacemos pumpAndSettle (evita cuelgues)
        expect(find.byType(InteractiveViewer), findsOneWidget);
        expect(find.text('No se pudo cargar la imagen'), findsNothing);
      },
    );

    testWidgets(
      'muestra mensaje de error cuando el archivo no existe',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PhotoViewerScreen(uri: '/archivo/que/no/existe.png'),
          ),
        );

        expect(find.text('No se pudo cargar la imagen'), findsOneWidget);
        expect(find.byType(InteractiveViewer), findsNothing);
      },
    );
  });
}
