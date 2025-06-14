import 'dart:io';
import 'dart:typed_data';                       // <- untuk Uint8List
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';     // pastikan versi >=4.0.0
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'permission_handler.dart';                // path relatif ke file Anda

class GenerateQRCodePage extends StatefulWidget {
  final String kodeKuisRandom;
  const GenerateQRCodePage({super.key, required this.kodeKuisRandom});

  @override
  State<GenerateQRCodePage> createState() => _GenerateQRCodePageState();
}

class _GenerateQRCodePageState extends State<GenerateQRCodePage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _saveQRCode() async {
    // tangkap messenger sebelum await
    final messenger = ScaffoldMessenger.of(context);

    // 1️⃣ Minta izin terpusat
    final granted = await PermissionService.requestStorage(context);
    if (!granted || !mounted) return;

    try {
      // 2️⃣ Siapkan direktori & nama file
      final dir = await getApplicationDocumentsDirectory();
      if (!mounted) return;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'qr_${widget.kodeKuisRandom}_$ts.png';
      final fullPath = '${dir.path}/$fileName';

      // 3️⃣ Tangkap screenshot jadi bytes
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
        SnackBar(content: Text('QR Code berhasil disimpan di: $fullPath')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate QR Code')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Screenshot(
              controller: _screenshotController,
              child: Container(
                color: Colors.white,              // latar agar kontras
                padding: const EdgeInsets.all(12),
                child: QrImageView(                // gunakan QrImageView
                  data: widget.kodeKuisRandom,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveQRCode,
              icon: const Icon(Icons.download),
              label: const Text('Download QR sebagai PNG'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
