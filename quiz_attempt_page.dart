import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizAttemptsPage extends StatefulWidget {
  final int quizId;
  final String? quizTitle;
  const QuizAttemptsPage({super.key, required this.quizId, this.quizTitle});

  @override
  State<QuizAttemptsPage> createState() => _QuizAttemptsPageState();
}

class _QuizAttemptsPageState extends State<QuizAttemptsPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _futureAttempts;

  @override
  void initState() {
    super.initState();
    _futureAttempts = _fetchAttempts();
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Pull student attempts for one quiz
  // ──────────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchAttempts() async {
    final resp =
        await supabase
            .from('quiz_attempts')
            .select('''
          id,
          user_id,
          started_at,
          submitted_at,
          profiles!inner (
            full_name,
            nim_nip,
            photo_url
          )
          ''')
            .eq('quiz_id', widget.quizId)
            .order('submitted_at')
            .execute();

    if (resp.error != null) throw resp.error!;
    return List<Map<String, dynamic>>.from(resp.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.quizTitle ?? 'Attempts')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureAttempts,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final attempts = snapshot.data!;
          if (attempts.isEmpty) {
            return const Center(
              child: Text('Belum ada mahasiswa yang submit.'),
            );
          }

          return ListView.separated(
            itemCount: attempts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final row = attempts[index];
              final prof = row['profiles'] as Map<String, dynamic>;
              final submittedAt = row['submitted_at'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    prof['photo_url'] ??
                        'https://placehold.co/48x48/png?text=?',
                  ),
                ),
                title: Text(prof['full_name'] ?? '-'),
                subtitle: Text(
                  'NIM: ${prof['nim_nip'] ?? '-'}\nSubmit: ${submittedAt ?? '-'}',
                ),
                onTap: () {
                  // TODO: Navigate to detail essay review page if needed
                },
              );
            },
          );
        },
      ),
    );
  }
}

extension on PostgrestTransformBuilder<PostgrestList> {
  execute() {}
}
