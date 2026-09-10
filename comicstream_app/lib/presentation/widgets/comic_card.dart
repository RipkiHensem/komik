import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/comic.dart';
import '../widgets/proxied_image.dart';
import 'hover_builder.dart';

/// World-class modern comic card widget
/// Portrait cover with double-bezel border, frosted glass overlays, and refined metadata
class ComicCard extends StatefulWidget {
  final Comic comic;
  final VoidCallback? onTap;
  final bool showBadge;

  const ComicCard({
    super.key,
    required this.comic,
    this.onTap,
    this.showBadge = true,
  });

  @override
  State<ComicCard> createState() => _ComicCardState();
}

class _ComicCardState extends State<ComicCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isActive => _isHovered || _isPressed;

  bool get _isRecentlyUpdated {
    return DateTime.now().difference(widget.comic.updatedAt).inHours < 24;
  }

  @override
  Widget build(BuildContext context) {
    final comic = widget.comic;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.025 : 1.0),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _isActive ? AppColors.cardHover : AppColors.card,
              border: Border.all(
                color: _isActive
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.glassBorder,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isActive ? 0.35 : (AppColors.isDark ? 0.25 : 0.06),
                  ),
                  blurRadius: _isActive ? 16 : 10,
                  offset: Offset(0, _isActive ? 6 : 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image with overlays
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover Image
                      ProxiedImage(
                        imageUrl: comic.coverUrl,
                        fit: BoxFit.cover,
                      ),

                      // Refined ambient bottom vignette
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.cardOverlay,
                          ),
                        ),
                      ),

                      // Top-left: Frosted time badge
                      if (widget.showBadge)
                        Positioned(
                          top: 7,
                          left: 7,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 10,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    const SizedBox(width: 3.5),
                                    Text(
                                      comic.lastUpdatedRelative,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFFCBD5E1),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Top-right: Format flag
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            comic.formatFlag,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),

                      // "NEW" badge if recently updated (vibrant gradient pill)
                      if (_isRecentlyUpdated)
                        Positioned(
                          bottom: 7,
                          left: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF3B30).withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Title & metadata
                Padding(
                  padding: const EdgeInsets.all(9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comic.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            comic.formattedViews,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                width: 0.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  size: 10,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  comic.chapterCount > 0
                                      ? '${comic.chapterCount} Ch'
                                      : 'Ch. 1+',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrollable comic card for hero/featured showcase
class ComicCardHero extends StatelessWidget {
  final Comic comic;
  final VoidCallback? onTap;

  const ComicCardHero({
    super.key,
    required this.comic,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HoverWidget(
      onTap: onTap,
      scale: 1.015,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.card,
          border: Border.all(
            color: Colors.white.withValues(alpha: AppColors.isDark ? 0.1 : 0.06),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: AppColors.isDark ? 0.45 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background cover
            ProxiedImage(
              imageUrl: comic.coverUrl,
              fit: BoxFit.cover,
            ),

            // Cinematic dark gradient overlay with deep color tint
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.7),
                    const Color(0xF5090B10),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Top trending & rating badges (scrollable to prevent overflow on small devices)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'TRENDING',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Rating badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.ratingStar.withValues(alpha: 0.4),
                              width: 0.6,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColors.ratingStar,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                comic.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ratingStar,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (comic.chapterCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.45),
                                width: 0.6,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  size: 12,
                                  color: AppColors.primaryLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${comic.chapterCount} Chapter',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        // Format Flag
                        Text(
                          comic.formatFlag,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    comic.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Synopsis preview
                  Text(
                    comic.synopsis,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // "Mulai Baca" button with nested button-in-button icon architecture
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Mulai Baca',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
