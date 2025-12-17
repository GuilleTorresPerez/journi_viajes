// coverage:ignore-file
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'package:image_picker/image_picker.dart';

class MockImagePicker extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    int? imageQuality,
    double? maxHeight,
    double? maxWidth,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = false,
    required ImageSource source,
  }) async {
    // Crear un archivo temporal fake
    final image = img.Image(width: 100, height: 100);
    img.fill(image, color: img.ColorRgb8(255, 0, 0));

    // Convertir a PNG
    final pngBytes = Uint8List.fromList(img.encodePng(image));

    // Guardar en un archivo temporal
    final file = File('${Directory.systemTemp.path}/fake_image.png');
    await file.writeAsBytes(pngBytes);

    return XFile(file.path);
  }

  @override
  Future<XFile?> pickVideo({
    required ImageSource source,
    Duration? maxDuration,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    // Devuelve un video de prueba para tests
    return XFile('test/assets/test_video.mp4');
  }
}
