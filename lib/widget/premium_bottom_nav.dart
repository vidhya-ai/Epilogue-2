import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;

  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/medications');
        break;
      case 2:
        context.go('/observations');
        break;
      case 3:
        context.go('/moments');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.7)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  context,
                  icon: Icons.home_rounded,
                  index: 0,
                ),
                _navItem(
                  context,
                  icon: Icons.medication_outlined,
                  index: 1,
                ),
                _navItem(
                  context,
                  icon: Icons.description_outlined,
                  index: 2,
                ),
                _navItem(
                  context,
                  icon: Icons.favorite_border_rounded,
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required int index,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _onTap(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF8E7CB1).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 28,
          color: isActive
              ? const Color(0xFF6B5B95)
              : const Color(0xFF8B7BA8),
        ),
      ),
    );
  }
}