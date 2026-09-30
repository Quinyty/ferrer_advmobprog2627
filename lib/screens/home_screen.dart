import 'package:flutter/material.dart';
import 'product_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _chatColor = Color(0xff3b4f9b);
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onTappedBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _selectedIndex == 1 ? _chatColor : null,
        foregroundColor: _selectedIndex == 1 ? Colors.white : null,
        title: Text(
          _selectedIndex == 0
              ? 'Shop'
              : _selectedIndex == 1
              ? 'Chats'
              : 'Profile',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [ProductScreen(), ChatScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTappedBar,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Shop'),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            label: 'Chats',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
