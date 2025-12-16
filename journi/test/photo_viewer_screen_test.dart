import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/PhotoViewerScreen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhotoViewerScreen', () {
    testWidgets(
      'muestra la imagen cuando el archivo existe',
      (WidgetTester tester) async {
        // 🔹 Crear archivo temporal
        final tempDir = await Directory.systemTemp.createTemp();
        final imageFile = File('${tempDir.path}/test_image.png');

        // PNG mínimo válido (1x1 pixel)
        await imageFile.writeAsBytes(<int>[
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]);

        // 🔹 Renderizar widget
        await tester.pumpWidget(
          MaterialApp(
            home: PhotoViewerScreen(uri: imageFile.path),
          ),
        );

        // 🔹 Comprobaciones
        expect(find.byType(InteractiveViewer), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(find.text('No se pudo cargar la imagen'), findsNothing);
      },
    );

    testWidgets(
      'muestra mensaje de error cuando el archivo no existe',
      (WidgetTester tester) async {
        const fakePath = '/ruta/que/no/existe.png';

        await tester.pumpWidget(
          const MaterialApp(
            home: PhotoViewerScreen(uri: fakePath),
          ),
        );

        expect(find.text('No se pudo cargar la imagen'), findsOneWidget);
        expect(find.byType(Image), findsNothing);
      },
    );
  });
}
