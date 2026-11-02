import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Pratinjau gambar layar penuh (banner/dokumen berupa gambar) dengan zoom cubit.
class PratinjauGambarScreen extends StatelessWidget {
  const PratinjauGambarScreen({super.key, required this.judul, required this.bytes});

  final String judul;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(judul)),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Gambar tidak dapat ditampilkan.', textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
