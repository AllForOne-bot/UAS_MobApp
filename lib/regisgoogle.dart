import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tubes_mobapp/Menu.dart';

class Registrasigoogle extends StatefulWidget {
  const Registrasigoogle({super.key});

  @override
  State<Registrasigoogle> createState() => _RegistrasigoogleState();
}

class _RegistrasigoogleState extends State<Registrasigoogle> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nimController = TextEditingController();
  String _status = 'Mahasiswa';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkIfProfileExists();
  }

  Future<void> _checkIfProfileExists() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final profile =
          await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();

      if (profile != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Menu()),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User tidak ditemukan, silakan login ulang.'),
        ),
      );
      setState(() => _loading = false);
      return;
    }

    try {
      // Cek apakah NIM/NIP sudah digunakan
      final existingNim =
          await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('nim_nip', int.parse(_nimController.text))
              .maybeSingle();

      if (existingNim != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NIM/NIP sudah digunakan.')),
        );
        setState(() => _loading = false);
        return;
      }
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error database: ${e.message}')));
      setState(() => _loading = false);
      return;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      setState(() => _loading = false);
      return;
    }

    try {
      // Simpan data ke tabel profiles
      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'full_name': _fullNameController.text,
        'nim_nip': int.parse(_nimController.text),
        'status': _status,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi profil berhasil')),
      );

      // Navigasi ke halaman Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Menu()),
      );
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error database: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lengkapi Profil')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 24),
              const Text(
                'Lengkapi Data Profil',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (value) => value!.isEmpty ? 'Masukkan nama' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nimController,
                decoration: const InputDecoration(labelText: 'NIM / NIP'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Masukkan NIM/NIP';
                  if (int.tryParse(value) == null) return 'Hanya boleh angka';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(
                    value: 'Mahasiswa',
                    child: Text('Mahasiswa'),
                  ),
                  DropdownMenuItem(value: 'Dosen', child: Text('Dosen')),
                ],
                onChanged: (value) => setState(() => _status = value!),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? 'Menyimpan...' : 'Simpan Profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
