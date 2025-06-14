import 'dart:io';
import 'dart:typed_data';                        // agar Uint8List dikenali
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';      // versi ≥4.0.0
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'permission_handler.dart';                 // pastikan path relatif benar

class KelasDetailPage extends StatefulWidget {
  final Map<String, dynamic> kelasData;
  const KelasDetailPage({super.key, required this.kelasData});

  @override
  State<KelasDetailPage> createState() => _KelasDetailPageState();
}

class _KelasDetailPageState extends State<KelasDetailPage> {
  final _screenshotController = ScreenshotController();

  Future<void> _saveQrAsPng() async {
    // Tangkap messenger sebelum await
    final messenger = ScaffoldMessenger.of(context);

    // 1️⃣ Minta izin terpusat
    final granted = await PermissionService.requestStorage(context);
    if (!granted || !mounted) return;

    try {
      // 2️⃣ Siapkan direktori & nama file
      final dir = await getApplicationDocumentsDirectory();
      if (!mounted) return;
      final kode = widget.kelasData['kode_kuis']?.toString() ?? '';
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

      // 4️⃣ Simpan ke disk
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

  void _navigateToSoalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SoalPage(
          kodeKuisRandom: widget.kelasData['kode_kuis']?.toString() ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mataKuliah = widget.kelasData['mata_kuliah']?.toString()
        ?? widget.kelasData['title']?.toString()
        ?? '-';
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
                color: Colors.white,           // latar agar kontras capture
                padding: const EdgeInsets.all(12),
                child: QrImageView(             // QrImageView untuk qr_flutter ≥4.x
                  data: kodeKuis,
                  size: 250.0,
                  backgroundColor: Colors.white,
                ),
                // Jika masih memakai qr_flutter 3.x, pakai:
                // child: QrImage(
                //   data: kodeKuis,
                //   version: QrVersions.auto,
                //   size: 250.0,
                // ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveQrAsPng,
              child: const Text('Download QR sebagai PNG'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToSoalPage,
              child: const Text('Buat Soal'),
            ),
          ],
        ),
      ),
    );
  }
}

class SoalPage extends StatelessWidget {
  final String kodeKuisRandom;
  const SoalPage({super.key, required this.kodeKuisRandom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Soal')),
      body: Center(
        child: Text('Membuat soal untuk kode kuis: $kodeKuisRandom'),
      ),
    );
  }
}
