import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';

class GenerateQRCodePage extends StatefulWidget {
  final String kodeKuisRandom;

  const GenerateQRCodePage({Key? key, required this.kodeKuisRandom}) : super(key: key);

  @override
  _GenerateQRCodePageState createState() => _GenerateQRCodePageState();
}

class _GenerateQRCodePageState extends State<GenerateQRCodePage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  // Fungsi untuk menyimpan QR sebagai gambar PNG
  Future<void> _saveQRCode() async {
    try {
      // Meminta izin penyimpanan
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin penyimpanan ditolak')),
        );
        return;
      }

      // Direktori penyimpanan
      final directory = await getApplicationDocumentsDirectory();

      // Gunakan timestamp agar nama file unik
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/qr_${widget.kodeKuisRandom}_$timestamp.png';

      // Capture QR code sebagai gambar
      final Uint8List? pngBytes = await _screenshotController.capture();
      if (pngBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menangkap gambar QR Code')),
        );
        return;
      }

      // Simpan gambar ke file
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR Code berhasil disimpan di: $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat menyimpan QR: $e')),
      );
    }
  }

  // Navigasi ke halaman soal
  void _navigateToSoalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SoalPage(kodeKuisRandom: widget.kodeKuisRandom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generate QR Code")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menampilkan QR Code
            Screenshot(
              controller: _screenshotController,
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 200.0,
                  height: 200.0,
                  child: QrImageView(
                    data: widget.kodeKuisRandom,
                    gapless: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveQRCode,
              icon: const Icon(Icons.download),
              label: const Text("Download QR sebagai PNG"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToSoalPage,
              child: const Text("Buat Soal"),
            ),
          ],
        ),
      ),
    );
  }
}

// Halaman dummy SoalPage - bisa kamu ganti dengan implementasi soal asli
class SoalPage extends StatelessWidget {
  final String kodeKuisRandom;

  const SoalPage({Key? key, required this.kodeKuisRandom}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Soal")),
      body: Center(
        child: Text('Membuat soal untuk kode kuis: $kodeKuisRandom'),
      ),
    );
  }
}
