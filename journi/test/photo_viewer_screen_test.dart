import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/PhotoViewerScreen.dart';

void main() {
  testWidgets(
    'muestra mensaje de error cuando el archivo no existe',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PhotoViewerScreen(uri: '/ruta/que/no/existe.jpg'),
        ),
      );

      expect(find.text('No se pudo cargar la imagen'), findsOneWidget);
    },
  );
}
