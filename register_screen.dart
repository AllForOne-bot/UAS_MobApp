import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _status = 'Mahasiswa';
  bool _loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password tidak cocok')));
      return;
    }

    setState(() => _loading = true);

    try {
      // Cek apakah email sudah ada di tabel profiles
      final existingEmail =
          await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('email', _emailController.text)
              .maybeSingle();

      if (existingEmail != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Email sudah digunakan.')));
        setState(() => _loading = false);
        return;
      }

      // Cek apakah NIM/NIP sudah digunakan
      final existingNim =
          await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('nim_nip', int.parse(_nimController.text))
              .maybeSingle();

      if (existingNim != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NIM/NIP sudah digunakan.')),
        );
        setState(() => _loading = false);
        return;
      }

      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final user = authResponse.user;
      if (user != null) {
        await Supabase.instance.client.from('profiles').insert({
          'id': user.id,
          'full_name': _nameController.text,
          'nim_nip': int.parse(_nimController.text),
          'email': _emailController.text,
          'status': _status,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil, silakan login.')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registrasi gagal.')));
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage =
          e is AuthApiException &&
                  e.message.contains('email') &&
                  e.message.contains('already registered')
              ? 'Email sudah terdaftar. Silakan login atau gunakan email lain.'
              : 'Terjadi kesalahan: $e';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi Akun - Kerja Pintar')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 24),
              const Text(
                'Buat akun baru',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
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
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Masukkan email' : null,
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator:
                    (value) => value!.isEmpty ? 'Masukkan password' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password',
                ),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Masukkan konfirmasi password' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: Text(_loading ? 'Mendaftarkan...' : 'Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
