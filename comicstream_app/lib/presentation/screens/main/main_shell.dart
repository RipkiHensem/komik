import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/hover_builder.dart';

/// Main shell with modern floating frosted glass navigation dock
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _navItems = [
    (icon: Icons.explore_rounded, activeIcon: Icons.explore_rounded, label: 'Explore', path: '/home'),
    (icon: Icons.search_rounded, activeIcon: Icons.manage_search_rounded, label: 'Search', path: '/search'),
    (icon: Icons.bookmark_outline_rounded, activeIcon: Icons.bookmark_rounded, label: 'Bookmark', path: '/bookmarks'),
    (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil', path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.bottomNav,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.glassBorder,
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: AppColors.isDark ? 0.45 : 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(_navItems.length, (index) {
                            final item = _navItems[index];
                            final isActive = index == currentIndex;

                            return Expanded(
                              child: HoverWidget.builder(
                                scale: 1.06,
                                enableScale: true,
                                onTap: () {
                                  if (index != currentIndex) {
                                    context.go(item.path);
                                  }
                                },
                                builder: (context, isHovered, _) {
                                  final itemColor = isActive
                                      ? AppColors.primary
                                      : (isHovered ? AppColors.textPrimary : AppColors.textMuted);

                                  return Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOutCubic,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isActive ? 14 : 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppColors.primary.withValues(alpha: 0.16)
                                            : (isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: isActive
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primary.withValues(alpha: 0.25),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isActive ? item.activeIcon : item.icon,
                                            size: 22,
                                            color: itemColor,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isActive
                                                  ? FontWeight.w700
                                                  : (isHovered ? FontWeight.w600 : FontWeight.w500),
                                              letterSpacing: 0.2,
                                              color: itemColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }
}
