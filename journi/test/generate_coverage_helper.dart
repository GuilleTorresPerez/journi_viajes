import 'dart:io';

// CONFIGURACIÓN
const String packageName = 'journi'; 
const String targetFile = 'test/coverage_helper_test.dart';

void main() async {
  final cwd = Directory.current;
  // Asumimos que ejecutas esto desde la raíz del proyecto
  final libDir = Directory('${cwd.path}/lib');

  if (!await libDir.exists()) {
    print('❌ Error: No se encontró la carpeta lib. Ejecuta el script desde la raíz del proyecto.');
    return;
  }

  print('🔍 Escaneando archivos en: ${libDir.path}...');

  final files = libDir.listSync(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.dart'))
      .cast<File>();

  final buffer = StringBuffer();
  
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// Script: test/generate_coverage_helper.dart');
  buffer.writeln('// ignore_for_file: unused_import');
  buffer.writeln();

  int count = 0;
  int ignoredCount = 0;

  for (final file in files) {
    final path = file.path.replaceAll(r'\', '/'); // Normalizar para Windows
    
    // --- FILTROS DE EXCLUSIÓN (Lógica de Ingeniería) ---
    
    // 1. Archivos generados
    if (path.endsWith('.g.dart')) { ignoredCount++; continue; }
    if (path.endsWith('.freezed.dart')) { ignoredCount++; continue; }
    if (path.endsWith('generated_plugin_registrant.dart')) { ignoredCount++; continue; }

    // 2. Archivos de entrada UI y Configuración
    if (path.endsWith('/main.dart')) { ignoredCount++; continue; } 
    
    // 3. Mocks y Tests dentro de lib (Basado en tu tree)
    // Excluimos integration_test si está dentro de lib
    if (path.contains('/integration_test/')) { ignoredCount++; continue; }
    // Excluimos mocks manuales
    if (path.contains('mock')) { ignoredCount++; continue; } 
    // Excluimos carpetas de ejemplo
    if (path.contains('/example/')) { ignoredCount++; continue; }

    // --- FIN FILTROS ---

    // Obtener ruta relativa desde 'lib/'
    // Ejemplo: .../journi/lib/data/local/archivo.dart -> data/local/archivo.dart
    final relativePath = path.split('/lib/').last;
    
    buffer.writeln("import 'package:$packageName/$relativePath';");
    count++;
  }

  buffer.writeln();
  buffer.writeln('void main() {}');

  final outputFile = File(targetFile);
  await outputFile.writeAsString(buffer.toString());

  print('------------------------------------------------');
  print('✅ Archivo generado: $targetFile');
  print('📥 Archivos incluidos: $count');
  print('🗑️  Archivos excluidos (Generados/Mocks/Main): $ignoredCount');
  print('------------------------------------------------');
}