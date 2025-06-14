import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'kelas_detail_page.dart';  // Impor Halaman Detail Kelas

class TabInputKuis extends StatefulWidget {
  const TabInputKuis({Key? key}) : super(key: key);

  @override
  _TabInputKuisState createState() => _TabInputKuisState();
}

class _TabInputKuisState extends State<TabInputKuis> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _kelasFuture;

  @override
  void initState() {
    super.initState();
    _refreshList(); // Memuat data kelas
  }

  // Fungsi untuk refresh list kelas
  void _refreshList() {
    _kelasFuture = supabase
        .from('courses')  // Mengambil data dari tabel courses
        .select()
        .order('created_at', ascending: false)  // Mengurutkan data berdasarkan waktu pembuatan
        .then((data) => List<Map<String, dynamic>>.from(data));  // Mengubah data menjadi List
    setState(() {});
  }

  // Fungsi untuk generate kode kuis random
  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';  // Karakter untuk kode kuis
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  // Fungsi untuk menampilkan dialog tambah kelas
  Future<void> _showCreateDialog() async {
    final _mkController = TextEditingController();  // Controller untuk input nama mata kuliah
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tambah Kelas'),
        content: TextField(
          controller: _mkController,
          decoration: InputDecoration(labelText: 'Mata Kuliah'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final mk = _mkController.text.trim();
              if (mk.isEmpty) return;

              // Generate kode kuis random 6 karakter
              final kodeKuis = _generateRandomCode(6);

              // Menyimpan kelas ke dalam tabel 'quizzes'
              await supabase.from('quizzes').insert({
                'kode_kuis': kodeKuis, // Kode kuis yang dihasilkan
                'course_id': 1, // Misalnya ID mata kuliah yang relevan
                'title': mk, // Judul kelas atau mata kuliah
                'deadline': DateTime.now().add(Duration(days: 7)).toIso8601String(), // Contoh deadline
              });

              Navigator.pop(context);
              _refreshList(); // Refresh daftar kelas
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tab Input Kuis'),
        actions: [
          IconButton(onPressed: _showCreateDialog, icon: Icon(Icons.add)),  // Tombol untuk menambah kelas
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(  // Memuat data kelas
        future: _kelasFuture,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());  // Menunggu data dimuat
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(child: Text('Belum ada kelas.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final kelas = list[i];
              return ListTile(
                title: Text(kelas['mata_kuliah']),
                subtitle: Text('Kode: ${kelas['kode_kuis']}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KelasDetailPage(kelasData: kelas),  // Menampilkan detail kelas
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
