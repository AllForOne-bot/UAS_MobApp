import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data_mahasiswa.dart';

class PemilihanMatkulPage extends StatefulWidget {
  const PemilihanMatkulPage({super.key});

  @override
  State<PemilihanMatkulPage> createState() => _PemilihanMatkulPageState();
}

class _PemilihanMatkulPageState extends State<PemilihanMatkulPage> {
  final supabase = Supabase.instance.client;

  late Future<List<String>> _mataKuliahFuture;

  @override
  void initState() {
    super.initState();
    _mataKuliahFuture = fetchMataKuliah();
  }

  /// Ambil daftar mata kuliah dari tabel `courses`
  Future<List<String>> fetchMataKuliah() async {
    final data = await supabase.from('courses').select('Mata_kuliah');

    // Data berbentuk List<dynamic> → ekstrak kolom menjadi List<String>
    return data.map<String>((row) => row['Mata_kuliah'] as String).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Mata Kuliah')),
      body: FutureBuilder<List<String>>(
        future: _mataKuliahFuture,
        builder: (context, snapshot) {
          // Spinner saat loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Tampilkan error jika gagal
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat mata kuliah:\n${snapshot.error}'),
            );
          }

          final matkulList = snapshot.data ?? [];
          if (matkulList.isEmpty) {
            return const Center(child: Text('Belum ada mata kuliah.'));
          }

          // List mata kuliah
          return ListView.builder(
            itemCount: matkulList.length,
            itemBuilder: (context, index) {
              final matkul = matkulList[index];
              return ListTile(
                title: Text(matkul),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DataMahasiswaPage()),
                    ),
              );
            },
          );
        },
      ),
    );
  }
}
