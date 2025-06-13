import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tubes_mobapp/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://sxmqgbcjgppvidlaqdqd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4bXFnYmNqZ3BwdmlkbGFxZHFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTgwNDg1MSwiZXhwIjoyMDY1MzgwODUxfQ.8g0JHPunnVohDBV9yTiAQ04JbQqXb6d9wnjUGvBx7BI',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kerja Pintar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16.0),
          headlineSmall: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
