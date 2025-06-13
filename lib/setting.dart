import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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

  late TextEditingController _nameController;
  late TextEditingController _nimController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nimController = TextEditingController();
    fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    if (user == null) {
      setState(() {
        errorMsg = 'Anda belum login.';
        isLoading = false;
      });
      return;
    }

    try {
      final data =
          await supabase.from('profiles').select().eq('id', user!.id).single();

      if (!mounted) return;
      setState(() {
        profile = data;
        _nameController.text = data['full_name'] ?? '';
        _nimController.text = data['nim_nip'] ?? '';
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

  Future<void> updateProfile() async {
    try {
      await supabase
          .from('profiles')
          .update({
            'full_name': _nameController.text,
            'nim_nip': _nimController.text,
          })
          .eq('id', user!.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );

      fetchProfile();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui profil: $e')));
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final fileExt = path.extension(file.path);
    final fileName = const Uuid().v4();
    final storagePath = 'profile_pictures/$fileName$fileExt';

    try {
      final bytes = await file.readAsBytes();
      await supabase.storage
          .from('avatars')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(storagePath);

      await supabase
          .from('profiles')
          .update({'foto': imageUrl})
          .eq('id', user!.id);

      await fetchProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
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
    if (profile == null) {
      return const Center(child: Text('Profil tidak ditemukan.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: CircleAvatar(
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
          ),
          const SizedBox(height: 8),
          const Text(
            "Ketuk foto untuk mengganti",
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nimController,
            decoration: const InputDecoration(
              labelText: 'NIM/NIP',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: updateProfile,
            icon: const Icon(Icons.save),
            label: const Text('Simpan Perubahan'),
          ),
          const SizedBox(height: 20),

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
