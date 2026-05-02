import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import 'home_page.dart';
import 'history.dart';
import 'profile.dart';
import 'track.dart';

class MainBottomNav extends StatefulWidget {
  const MainBottomNav({super.key});

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> {
  int _currentIndex = 0;
  final Set<int> _loadedIndexes = {0};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to flow behind the navigation bar
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          4,
          (index) => _loadedIndexes.contains(index)
              ? _buildPage(index)
              : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: FadeInUp(
        duration: const Duration(milliseconds: 800),
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          decoration: BoxDecoration(
            color: AppColors.darkSurface.withAlpha(242),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(77),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(0, Icons.home_rounded, "Home"),
                _buildNavItem(1, Icons.map_rounded, "Track"),
                _buildNavItem(2, Icons.confirmation_number_rounded, "Tickets"),
                _buildNavItem(3, Icons.person_rounded, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _currentIndex = index;
        _loadedIndexes.add(index);
      }),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textMuted,
              size: 24,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FadeIn(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const TrackPage();
      case 2:
        return const HistoryPage();
      case 3:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }
}
