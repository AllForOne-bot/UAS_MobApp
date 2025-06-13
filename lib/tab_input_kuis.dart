import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Helper untuk generate string acak
String generateRandomString(int length) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return List.generate(
    length,
    (index) => chars[Random().nextInt(chars.length)],
  ).join();
}

class TabInputKuis extends StatefulWidget {
  const TabInputKuis({Key? key}) : super(key: key);

  @override
  State<TabInputKuis> createState() => _TabInputKuisState();
}

class _TabInputKuisState extends State<TabInputKuis> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> kelasList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKelas();
  }

  Future<void> fetchKelas() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('KELAS')
          .select()
          .order('id', ascending: true);
      setState(() {
        kelasList = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data kelas: $e')));
    }
  }

  Future<void> addKelasDialog() async {
    final TextEditingController mataKuliahController = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Tambah Kelas"),
            content: TextField(
              controller: mataKuliahController,
              decoration: const InputDecoration(labelText: "Mata Kuliah"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final mataKuliah = mataKuliahController.text.trim();
                  if (mataKuliah.isEmpty) return;

                  final kodeKuis = generateRandomString(6);
                  final idMk = generateRandomString(8);

                  try {
                    await supabase.from('KELAS').insert({
                      'mata_kuliah': mataKuliah,
                      'kode_kuis_random': kodeKuis,
                      'id_mk': idMk,
                    });

                    Navigator.pop(context);
                    fetchKelas();
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan: $e')),
                    );
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          ),
    );
  }

  Future<void> deleteKelas(int id) async {
    try {
      await supabase.from('KELAS').delete().eq('id', id);
      fetchKelas();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Kuis - KELAS'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: addKelasDialog),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : kelasList.isEmpty
              ? const Center(child: Text('Belum ada data kelas.'))
              : ListView.builder(
                itemCount: kelasList.length,
                itemBuilder: (context, index) {
                  final kelas = kelasList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${kelas['id']}')),
                      title: Text(kelas['mata_kuliah'] ?? 'Tanpa Nama'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID MK: ${kelas['id_mk'] ?? '-'}'),
                          Text(
                            'Kode Kuis: ${kelas['kode_kuis_random'] ?? '-'}',
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteKelas(kelas['id']),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
