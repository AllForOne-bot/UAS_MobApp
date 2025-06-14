import 'dart:io';
import 'dart:typed_data';                       // ✅ Agar Uint8List dikenali
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';     // Pastikan versi >=4.0.0
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'permission_handler.dart';                // Sesuaikan path relatif Anda

class KelasDetailPage extends StatefulWidget {
  final Map<String, dynamic> kelasData;
  const KelasDetailPage({super.key, required this.kelasData});

  @override
  State<KelasDetailPage> createState() => _KelasDetailPageState();
}

class _KelasDetailPageState extends State<KelasDetailPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _saveQrAsPng() async {
    // Tangkap messenger _sebelum_ await agar lint use_build_context_synchronous hilang
    final messenger = ScaffoldMessenger.of(context);

    // 1️⃣ Minta izin terpusat
    final granted = await PermissionService.requestStorage(context);
    if (!granted || !mounted) return;

    try {
      // 2️⃣ Siapkan direktori dan nama file
      final dir = await getApplicationDocumentsDirectory();
      if (!mounted) return;
      final kode = widget.kelasData['kode_kuis']?.toString() ?? 'unknown';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'QR_${kode}_$ts.png';
      final fullPath = '${dir.path}/$fileName';

      // 3️⃣ Tangkap QR sebagai bytes
      final Uint8List? pngBytes = await _screenshotController.capture();
      if (!mounted) return;
      if (pngBytes == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Gagal menangkap QR Code')),
        );
        return;
      }

      // 4️⃣ Simpan file
      await File(fullPath).writeAsBytes(pngBytes);
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('QR Code disimpan di: $fullPath')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mataKuliah = widget.kelasData['mata_kuliah']?.toString() ?? '-';
    final kodeKuis = widget.kelasData['kode_kuis']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kelas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Mata Kuliah: $mataKuliah'),
            const SizedBox(height: 24),
            Screenshot(
              controller: _screenshotController,
              child: Container(
                color: Colors.white,              // Biar kontras waktu capture
                padding: const EdgeInsets.all(12),
                child: QrImageView(                // 🆕 Gunakan QrImageView di qr_flutter 4.x
                  data: kodeKuis,
                  size: 250.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveQrAsPng,
              child: const Text('Download QR sebagai PNG'),
            ),
          ],
        ),
      ),
    );
  }
}
