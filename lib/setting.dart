import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final supabase = Supabase.instance.client;
  late final user = supabase.auth.currentUser;

  Map<String, dynamic>? profile;
  bool isLoading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    // Cegah crash kalau user belum login
    if (user == null) {
      setState(() {
        errorMsg = 'Anda belum login.';
        isLoading = false;
      });
      return;
    }

    try {
      // ⚠️ Pastikan tabel di Supabase bernama "profiles" (huruf kecil)
      final data =
          await supabase
              .from('profiles') // ✅ ganti jadi huruf kecil
              .select()
              .eq('id', user!.id) // kolom id = uid auth
              .single();

      if (!mounted) return;
      setState(() {
        profile = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMsg = 'Gagal memuat profil: $e';
        isLoading = false;
      });
    }
  }

  void changePassword() => showDialog(
    context: context,
    builder:
        (_) => AlertDialog(
          title: const Text('Ganti Password'),
          content: const Text('Fitur ini sedang dikembangkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMsg != null) return Center(child: Text(errorMsg!));
    if (profile == null)
      return const Center(child: Text('Profil tidak ditemukan.'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                profile!['foto'] != null
                    ? NetworkImage(profile!['foto'])
                    : null,
            child:
                profile!['foto'] == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
          ),
          const SizedBox(height: 16),
          InfoTile(
            label: 'Nama Lengkap',
            value: profile!['nama_lengkap'] ?? '-',
          ),
          InfoTile(label: 'NIM', value: profile!['nim'] ?? '-'),
          InfoTile(label: 'Status', value: profile!['status'] ?? '-'),
          InfoTile(label: 'Email', value: user?.email ?? '-'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: changePassword,
            icon: const Icon(Icons.lock),
            label: const Text('Ubah Password'),
          ),
        ],
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const InfoTile({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text(value),
  );
}
