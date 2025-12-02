import 'dart:io';
import 'package:flutter/material.dart';

class PhotoViewerScreen extends StatelessWidget {
  final String uri;

  const PhotoViewerScreen({Key? key, required this.uri}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final file = File(uri); // mediaUri apunta a un archivo local

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: file.existsSync()
            ? InteractiveViewer(
                child: Image.file(file, fit: BoxFit.contain),
              )
            : const Text(
                "No se pudo cargar la imagen",
                style: TextStyle(color: Colors.white),
              ),
      ),
    );
  }
}
