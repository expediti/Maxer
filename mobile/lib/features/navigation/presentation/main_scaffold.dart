import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../alerts/presentation/providers/alerts_provider.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/discover')) return 0;
    if (location.startsWith('/saved')) return 1;
    if (location.startsWith('/applications')) return 2;
    if (location.startsWith('/alerts')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/discover');
        break;
      case 1:
        context.go('/saved');
        break;
      case 2:
        context.go('/applications');
        break;
      case 3:
        context.go('/alerts');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.secondaryBackground,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1.0),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: AppDimensions.navBarHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  currentIndex: selectedIndex,
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search,
                  label: 'Discover',
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  currentIndex: selectedIndex,
                  icon: Icons.bookmark_border_outlined,
                  activeIcon: Icons.bookmark,
                  label: 'Saved',
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  currentIndex: selectedIndex,
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment,
                  label: 'Applications',
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  currentIndex: selectedIndex,
                  icon: Icons.notifications_none_outlined,
                  activeIcon: Icons.notifications,
                  label: 'Alerts',
                  badgeCount: unreadAlerts,
                ),
                _buildNavItem(
                  context: context,
                  index: 4,
                  currentIndex: selectedIndex,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = index == currentIndex;

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8, vertical: AppDimensions.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? AppColors.primaryGreen : AppColors.textMuted,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: AppColors.background,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.space4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: isSelected ? AppColors.primaryGreen : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

