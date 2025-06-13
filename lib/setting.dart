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
    print('User ID: ${user?.id}');
  try {
    final updates = {
      'full_name': _nameController.text,
      'nim_nip': _nimController.text,
    };

    final response = await supabase
        .from('profiles')
        .update(updates)
        .eq('id', user!.id);

    print('Update result: $response');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil berhasil diperbarui')),
    );

    fetchProfile();
  } catch (e) {
    print('Error saat update: $e');
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
    await supabase.storage
        .from('avatars')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    final imageUrl = supabase.storage
        .from('avatars')
        .getPublicUrl(storagePath);

    await supabase
        .from('profiles')
        .update({'avatar_url': imageUrl})
        .eq('id', user!.id);

    await fetchProfile();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto profil berhasil diperbarui')),
    );
  } catch (e) {
    print('Upload error: $e');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
  }
}

  void changePassword() {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Baru',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPassword = passwordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (newPassword.isEmpty || confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Isi semua kolom terlebih dahulu')),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password tidak cocok')),
                );
                return;
              }

              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password minimal 6 karakter')),
                );
                return;
              }

              try {
                await supabase.auth.updateUser(UserAttributes(password: newPassword));
                Navigator.pop(context); // Tutup dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password berhasil diubah')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal mengubah password: $e')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

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
                  profile!['avatar_url'] != null
                      ? NetworkImage(profile!['avatar_url'])
                      : null,
              child:
                  profile!['avatar_url'] == null
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
