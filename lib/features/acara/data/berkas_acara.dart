import 'dart:typed_data';

/// Jenis berkas hasil unduhan banner/dokumen acara. API tidak mengirim nama/ekstensi berkas,
/// jadi jenisnya dikenali dari byte awal (magic bytes).
enum JenisBerkas {
  pdf('pdf', 'application/pdf'),
  jpg('jpg', 'image/jpeg'),
  png('png', 'image/png'),
  docx('docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
  doc('doc', 'application/msword'),
  tidakDikenal('bin', 'application/octet-stream');

  const JenisBerkas(this.ekstensi, this.mime);

  final String ekstensi;
  final String mime;

  bool get gambar => this == jpg || this == png;
}

JenisBerkas deteksiBerkas(Uint8List b) {
  bool awal(List<int> sig) {
    if (b.length < sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (b[i] != sig[i]) return false;
    }
    return true;
  }

  if (awal(const [0x25, 0x50, 0x44, 0x46])) return JenisBerkas.pdf; // %PDF
  if (awal(const [0xFF, 0xD8, 0xFF])) return JenisBerkas.jpg;
  if (awal(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) return JenisBerkas.png;
  if (awal(const [0x50, 0x4B, 0x03, 0x04])) return JenisBerkas.docx; // ZIP (OOXML)
  if (awal(const [0xD0, 0xCF, 0x11, 0xE0])) return JenisBerkas.doc; // OLE2
  return JenisBerkas.tidakDikenal;
}
