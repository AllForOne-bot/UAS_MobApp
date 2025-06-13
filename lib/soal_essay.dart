import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PenilaianPage extends StatefulWidget {
  const PenilaianPage({super.key});

  @override
  State<PenilaianPage> createState() => _PenilaianPageState();
}

class _PenilaianPageState extends State<PenilaianPage> {
  List<dynamic> soalList = [];
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchSoal();
  }

  Future<void> fetchSoal() async {
    final response = await supabase.from('SOAL_KUIS').select();
    setState(() => soalList = response);
  }

  Future<void> updateNilai(int id, String nilai) async {
    await supabase.from('SOAL_KUIS').update({'nilai': nilai}).eq('id', id);
    fetchSoal();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nilai berhasil diperbarui')));
  }

  final Map<int, TextEditingController> nilaiControllers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Penilaian Soal')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: DataTable(
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Pertanyaan')),
              DataColumn(label: Text('Jawaban Essay')),
              DataColumn(label: Text('Jawaban Benar')),
              DataColumn(label: Text('Nilai')),
              DataColumn(label: Text('Aksi')),
            ],
            rows:
                soalList.map((soal) {
                  final id = soal['id'];
                  final nilaiController = nilaiControllers.putIfAbsent(
                    id,
                    () => TextEditingController(text: soal['nilai'] ?? ''),
                  );
                  return DataRow(
                    cells: [
                      DataCell(Text('$id')),
                      DataCell(
                        SizedBox(
                          width: 250,
                          child: Text(
                            soal['pertanyaan'] ?? '',
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(
                            soal['teks_jawaban_essay'] ?? '',
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            soal['teks_jawaban_benar'] ?? '',
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: nilaiController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.all(8),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        ElevatedButton(
                          onPressed:
                              () => updateNilai(id, nilaiController.text),
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}
