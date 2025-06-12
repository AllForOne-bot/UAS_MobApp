import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tubes_mobapp/login_screen.dart';

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

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final response = await supabase
        .from('PROFILES')
        .select()
        .eq('id', user!.id)
        .single();

    setState(() {
      profile = response;
      isLoading = false;
    });
  }

  void changePassword() {
    // Arahkan ke halaman ubah password, atau tampilkan form
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profile == null) {
      return const Center(child: Text('Profil tidak ditemukan.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: profile!['foto'] != null
                ? NetworkImage(profile!['foto'])
                : null,
            child: profile!['foto'] == null ? const Icon(Icons.person, size: 50) : null,
          ),
          const SizedBox(height: 16),
          InfoTile(label: 'Nama Lengkap', value: profile!['nama_lengkap'] ?? '-'),
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
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    );
  }
}
