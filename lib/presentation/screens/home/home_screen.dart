import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    FeedScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  static const List<String> _titles = ['Inicio', 'Explorar', 'Perfil'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToCreatePost() async {
    final result = await context.push('/create-post');
    // Si se creó una nueva publicación, actualizar el feed
    if (result == true && _selectedIndex == 0) {
      // Notificar al FeedScreen que recargue
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Botón Inicio
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.home_outlined,
                    label: 'Inicio',
                    isSelected: _selectedIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                ),
                
                // Botón Explorar
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.search_outlined,
                    label: 'Explorar',
                    isSelected: _selectedIndex == 1,
                    onTap: () => _onItemTapped(1),
                  ),
                ),
                
                // Botón Crear (central)
                Expanded(
                  child: _buildCreatePostButton(),
                ),
                
                // Botón Perfil
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.person_outline,
                    label: 'Perfil',
                    isSelected: _selectedIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isSelected ? _getFilledIcon(icon) : icon,
                key: ValueKey(isSelected),
                size: 24,
                color: isSelected 
                    ? AppColors.accent 
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePostButton() {
    return GestureDetector(
      onTap: _navigateToCreatePost,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.add,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFilledIcon(IconData outlineIcon) {
    switch (outlineIcon) {
      case Icons.home_outlined:
        return Icons.home;
      case Icons.search_outlined:
        return Icons.search;
      case Icons.person_outline:
        return Icons.person;
      default:
        return outlineIcon;
    }
  }
}
