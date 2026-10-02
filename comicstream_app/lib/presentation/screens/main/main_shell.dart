import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// Persistent, full-width bottom navigation with a restrained monochrome style.
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _navItems = [
    (icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore', path: '/home'),
    (icon: Icons.search_outlined, activeIcon: Icons.search, label: 'Search', path: '/search'),
    (icon: Icons.bookmark_border, activeIcon: Icons.bookmark, label: 'Bookmark', path: '/bookmarks'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var index = 0; index < _navItems.length; index++) {
      if (location.startsWith(_navItems[index].path)) return index;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bottomNav,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isActive = index == currentIndex;
                final itemColor = isActive
                    ? AppColors.textPrimary
                    : AppColors.textMuted;

                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: isActive,
                    label: item.label,
                    child: InkWell(
                      onTap: () {
                        if (!isActive) context.go(item.path);
                      },
                      child: SizedBox(
                        height: 64,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isActive ? item.activeIcon : item.icon,
                              size: 22,
                              color: itemColor,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: itemColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: isActive ? 12 : 0,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
