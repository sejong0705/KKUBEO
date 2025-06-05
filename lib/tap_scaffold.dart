import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'home_page.dart';
import 'my_page.dart';

class TabScaffold extends StatefulWidget {
  final int currentIndex;

  const TabScaffold({super.key, required this.currentIndex});

  @override
  State<TabScaffold> createState() => _TabScaffoldState();
}

class _TabScaffoldState extends State<TabScaffold> {
  late int _currentIndex;

  final List<Widget> _pages = [
    CalendarPage(),
    HomePage(),
    MyPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex; //부모한테 받은 값으로 초기 화면 보여줌
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}
