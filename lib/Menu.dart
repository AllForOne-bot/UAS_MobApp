import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tubes_mobapp/Home_Menu.dart';
import 'package:tubes_mobapp/tab_input_kuis.dart';
import 'package:tubes_mobapp/settings.dart';
import 'package:tubes_mobapp/soal_essay.dart';

class Menu extends StatefulWidget {
  static const routeName = '/menu';
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
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
    final status = prefs.getString('status') ?? 'Mahasiswa';

    setState(() {
      _userStatus = status;

      if (_userStatus == 'Mahasiswa') {
        _pages = [
          const TabHome(),
          const TabInputKuis(),
          const PenilaianPage(),
          const SettingsTab(),
        ];
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Soal'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Koreksi soal',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ];
      } else if (_userStatus == 'Dosen') {
        _pages = [const TabHome(), const TabInputKuis(), const SettingsTab()];
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'Bank Soal',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ];
      } else {
        _pages = [
          const Center(child: Text('Status tidak dikenali')),
          const SettingsTab(),
        ];
        _navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Tidak Valid',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ];
      }
    });
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
        selectedItemColor: Colors.deepPurple, // Warna ikon & label saat aktif
        unselectedItemColor: Colors.grey, // Warna ikon & label saat non-aktif
        backgroundColor: Colors.white, // Warna latar tab bar
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
