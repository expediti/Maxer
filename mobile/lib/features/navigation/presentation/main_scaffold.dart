import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  DateTime? _lastBackPressed;

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/discover')) return 0;
    if (location.startsWith('/explorer')) return 1;
    if (location.startsWith('/saved')) return 2;
    if (location.startsWith('/applications')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/discover');
        break;
      case 1:
        context.go('/explorer');
        break;
      case 2:
        context.go('/saved');
        break;
      case 3:
        context.go('/applications');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (selectedIndex != 0) {
          // Rule 7: Nested bottom nav tabs navigate back to Home tab first
          context.go('/discover');
        } else {
          // Rule 8: On root Home screen, display exit confirmation toast instead of abrupt termination
          final now = DateTime.now();
          if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
            _lastBackPressed = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Press back again to exit Rexam',
                  style: TextStyle(color: AppColors.primaryText),
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.elevatedSurface,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            );
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.mainBackground,
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.secondaryBackground,
            border: Border(
              top: BorderSide(
                color: AppColors.border,
                width: 1.0,
              ),
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
                    icon: LucideIcons.home,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    currentIndex: selectedIndex,
                    icon: LucideIcons.compass,
                    label: 'Explore',
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    currentIndex: selectedIndex,
                    icon: LucideIcons.bookmark,
                    label: 'Saved',
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    currentIndex: selectedIndex,
                    icon: LucideIcons.clipboardList,
                    label: 'Applications',
                  ),
                  _buildNavItem(
                    context: context,
                    index: 4,
                    currentIndex: selectedIndex,
                    icon: LucideIcons.user,
                    label: 'Profile',
                  ),
                ],
              ),
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
    required String label,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index, context),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.elevatedSurface : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? Border.all(color: AppColors.border, width: 1.0) : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.white : AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
