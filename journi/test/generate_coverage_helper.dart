import 'dart:io';

// CONFIGURACIÓN
const String packageName = 'journi';
const String targetFile = 'test/coverage_helper_test.dart';

void main() async {
  final cwd = Directory.current;
  final libDir = Directory('${cwd.path}/lib');

  if (!await libDir.exists()) {
    print('❌ Error: No se encontró la carpeta lib.');
    return;
  }

  print('🔍 Escaneando archivos en: ${libDir.path}...');

  final files = libDir
      .listSync(recursive: true)
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
    final path = file.path.replaceAll(r'\', '/');

    // --- FILTROS POR NOMBRE (Metadatos) ---
    if (path.endsWith('.g.dart')) {
      ignoredCount++;
      continue;
    }
    if (path.endsWith('.freezed.dart')) {
      ignoredCount++;
      continue;
    }
    if (path.endsWith('generated_plugin_registrant.dart')) {
      ignoredCount++;
      continue;
    }
    if (path.endsWith('/main.dart')) {
      ignoredCount++;
      continue;
    }
    if (path.contains('/integration_test/')) {
      ignoredCount++;
      continue;
    }
    if (path.contains('mock')) {
      ignoredCount++;
      continue;
    }
    if (path.contains('/example/')) {
      ignoredCount++;
      continue;
    }

    // --- FILTRO POR CONTENIDO (Análisis Estático) ---
    // Leemos el archivo para ver si es una "part" de otro
    try {
      final content = file.readAsStringSync();
      // Buscamos la directiva "part of" (ignorando espacios iniciales)
      if (content.contains(RegExp(r'^\s*part of', multiLine: true))) {
        // Es un archivo parcial, no se puede importar directamente.
        // Se cargará a través de su archivo padre.
        ignoredCount++;
        continue;
      }
    } catch (e) {
      print('⚠️ No se pudo leer el archivo $path: $e');
      continue;
    }

    // --- GENERACIÓN DE IMPORT ---
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
  print('📥 Archivos importados: $count');
  print('🙈 Archivos ignorados (Parts/Generados/Mocks): $ignoredCount');
  print('------------------------------------------------');
}
