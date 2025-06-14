import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class TeacherQuestionPage extends StatefulWidget {
  final String quizCode;
  const TeacherQuestionPage({super.key, required this.quizCode});

  @override
  State<TeacherQuestionPage> createState() => _TeacherQuestionPageState();
}

class _TeacherQuestionPageState extends State<TeacherQuestionPage> {
  final _questionController = TextEditingController();
  final _answerControllers =
      List.generate(5, (_) => TextEditingController());
  final _isCorrect = List.generate(5, (_) => false);
  File? _questionImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _questionImage = File(picked.path));
    }
  }

  Future<void> _submitQuestion() async {
    final messenger = ScaffoldMessenger.of(context); 
    final text = _questionController.text.trim();
    if (text.isEmpty) return;

    String? imageUrl;
    if (_questionImage != null) {
      // 1️⃣ Build nama file & path
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_questionImage!.path.split('/').last}';
      final storagePath = '${widget.quizCode}/$fileName';

      // 2️⃣ Upload file (pakai upload, bukan uploadBinary)
      await Supabase.instance.client.storage
          .from(widget.quizCode)
          .upload(storagePath, _questionImage!);

      // 3️⃣ Dapatkan publicUrl
      imageUrl = Supabase.instance.client.storage
          .from(widget.quizCode)
          .getPublicUrl(storagePath);
    }

    // 4️⃣ Ambil quiz_id tanpa unnecessary_cast
    final Map<String, dynamic> quizResp = 
        await Supabase.instance.client
            .from('quizzes')
            .select('id')
            .eq('kode_kuis', widget.quizCode)
            .single();
    final quizId = quizResp['id'];

    // 5️⃣ Insert question, ambil kembali sebagai Map
    final Map<String, dynamic> insertedQ = 
        await Supabase.instance.client
            .from('questions')
            .insert({
              'quiz_id': quizId,
              'question_text': text,
              'image_url': imageUrl,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
    final questionId = insertedQ['id'];

    // 6️⃣ Insert tiap jawaban
    for (var i = 0; i < 5; i++) {
      final ansText = _answerControllers[i].text.trim();
      if (ansText.isEmpty) continue;
      await Supabase.instance.client.from('answers').insert({
        'question_id': questionId,
        'answer_text': ansText,
        'score': _isCorrect[i] ? 1 : 0,
      });
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Pertanyaan berhasil dibuat.')),
    );

    // 7️⃣ Reset form
    _questionController.clear();
    for (final c in _answerControllers) {
      c.clear();
    }
    setState(() {
      for (var i = 0; i < _isCorrect.length; i++) {
        _isCorrect[i] = false;
      }
      _questionImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Input Soal – ${widget.quizCode}'),
        backgroundColor: const Color(0xFF5D7092),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pertanyaan'),
            TextField(controller: _questionController),
            const SizedBox(height: 10),
            if (_questionImage != null)
              Image.file(_questionImage!, height: 150),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Upload Gambar Soal'),
            ),
            const Divider(),
            // Daftar 5 jawaban tanpa menggunakan {} di if/for
            for (var i = 0; i < 5; i++)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _answerControllers[i],
                      decoration: InputDecoration(
                        labelText:
                            'Jawaban ${String.fromCharCode(65 + i)}',
                      ),
                    ),
                  ),
                  Checkbox(
                    value: _isCorrect[i],
                    onChanged: (v) =>
                        setState(() => _isCorrect[i] = v ?? false),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D7092),
              ),
              child: const Text(
                'Simpan Pertanyaan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
