import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tubes_mobapp/Home_Menu.dart';
import 'package:tubes_mobapp/settings.dart';
// import 'grafik.dart';
// import 'kontrol.dart';
// import 'settings.dart'; // pastikan Settings tidak butuh authService

class Menu extends StatefulWidget {
  static var routeName;
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
    final status =
        prefs.getString('status') ?? 'Mahasiswa'; // default Mahasiswa

    setState(() {
      _userStatus = status;

      if (_userStatus == 'Mahasiswa') {
        _pages = [
          // const Grafik(),
          // const Kontrol(),
          const TabHome(), // ganti dengan widget asli
          const HomeScreen(),
          const Placeholder(), // Settings
        ];
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Soal'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ];
      } else if (_userStatus == 'Dosen') {
        _pages = [
          // const Grafik(),
          // const MonitorPage(),
          const TabHome(),
          const HomeScreen(),
          const Placeholder(),
        ];
        _navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'Monitor',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ];
      } else {
        // Default jika status tidak dikenal
        _pages = [const Placeholder(), const Placeholder()];
        _navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.error),
            label: 'Error',
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
      ),
    );
  }
}
