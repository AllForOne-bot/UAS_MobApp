import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tubes_mobapp/Home_Menu.dart';
import 'package:tubes_mobapp/pemilihan_matkul.dart';
import 'package:tubes_mobapp/tab_input_kuis.dart';
import 'package:tubes_mobapp/setting.dart';

class Menu extends StatefulWidget {
  static const routeName = '/menu';
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  final supabase = Supabase.instance.client;
  int _currentIndex = 0;
  late PageController _pageController;
  String _userStatus = '';
  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStatus = prefs.getString('status');

    print('Saved status from SharedPreferences: $savedStatus'); // Debug log

    if (savedStatus != null && savedStatus.isNotEmpty) {
      setState(() {
        _userStatus = savedStatus;
      });
      _loadPagesAndNavItems();
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _pages = [const Center(child: Text('User tidak ditemukan'))];
        _navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.error),
            label: 'Error',
          ),
        ];
      });
      return;
    }

    try {
      final data =
          await supabase
              .from('profiles')
              .select('status')
              .eq('id', user.id)
              .single();

      final status = data['status'] ?? 'Mahasiswa';
      print('Fetched status from Supabase: $status'); // Debug log

      // Simpan status ke SharedPreferences
      await prefs.setString('status', status);

      setState(() {
        _userStatus = status;
      });
      _loadPagesAndNavItems();
    } catch (e) {
      setState(() {
        _pages = [const Center(child: Text('Gagal memuat status pengguna'))];
        _navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.error),
            label: 'Error',
          ),
        ];
      });
    }
  }

  void _loadPagesAndNavItems() {
    if (_userStatus == 'Mahasiswa') {
      setState(() {
        _pages = [const TabHome(), const TabInputKuis(), const SettingsTab()];
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Soal'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Soal Essay',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ];
      });
    } else if (_userStatus == 'Dosen') {
      setState(() {
        _pages = [
          const TabHome(),
          const TabInputKuis(),
          const PemilihanMatkulPage(),
          const SettingsTab(),
        ];
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'Input Kuis',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'Penilaian',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ];
      });
    } else {
      setState(() {
        _pages = [const Center(child: Text('Status tidak dikenali'))];
        _navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Tidak Valid',
          ),
        ];
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.jumpToPage(index);
          });
        },
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
