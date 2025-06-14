import 'dart:io';
import 'dart:typed_data';                 // 🟢 Tambahkan agar Uint8List dikenali
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'permission_handler.dart';          // pastikan path relatif/import-nya benar

class GenerateQRCodePage extends StatefulWidget {
  final String kodeKuisRandom;
  const GenerateQRCodePage({Key? key, required this.kodeKuisRandom}) : super(key: key);

  @override
  State<GenerateQRCodePage> createState() => _GenerateQRCodePageState();
}

class _GenerateQRCodePageState extends State<GenerateQRCodePage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _saveQRCode() async {
    // 1️⃣ Minta izin lewat PermissionService
    final granted = await PermissionService.requestStorage(context);
    if (!granted) return;

    // 2️⃣ Siapkan path file
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'qr_${widget.kodeKuisRandom}_$timestamp.png';
    final fullPath = '${dir.path}/$fileName';

    try {
      // 3️⃣ Tangkap screenshot sebagai bytes
      final Uint8List? pngBytes = await _screenshotController.capture();
      if (pngBytes == null) {
        _showSnack('Gagal menangkap QR Code');
        return;
      }

      // 4️⃣ Tulis file ke disk
      final file = File(fullPath);
      await file.writeAsBytes(pngBytes);

      _showSnack('QR Code berhasil disimpan di: $fullPath');
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
                color: Colors.white,             // agar latar putih
                padding: const EdgeInsets.all(12),
                child: QrImageView(               // gunakan QrImageView (sesuai versi terbaru)
                  data: widget.kodeKuisRandom,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveQRCode,
              icon: const Icon(Icons.download),
              label: const Text('Download QR sebagai PNG'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
