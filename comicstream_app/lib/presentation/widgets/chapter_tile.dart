import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/chapter.dart';
import 'proxied_image.dart';

/// Chapter tile widget with modern double-bezel surface and vibrant NEW badge
class ChapterTile extends StatefulWidget {
  final Chapter chapter;
  final String? coverUrl;
  final bool isRead;
  final bool isNew;
  final VoidCallback? onTap;

  const ChapterTile({
    super.key,
    required this.chapter,
    this.coverUrl,
    this.isRead = false,
    this.isNew = false,
    this.onTap,
  });

  @override
  State<ChapterTile> createState() => _ChapterTileState();
}

class _ChapterTileState extends State<ChapterTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isActive => _isHovered || _isPressed;

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final isRead = widget.isRead;
    final isNew = widget.isNew;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (value) => setState(() => _isPressed = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : (_isHovered ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isRead
                  ? (AppColors.isDark
                      ? (_isActive ? const Color(0xFF0D1018) : const Color(0xFF07090F))
                      : (_isActive ? const Color(0xFFE9EDF3) : const Color(0xFFF1F5F9)))
                  : (_isActive ? AppColors.cardHover : AppColors.surface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isActive
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : (isRead
                        ? Colors.white.withValues(alpha: 0.04)
                        : AppColors.glassBorder),
                width: 0.8,
              ),
              boxShadow: _isActive
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          child: Row(
            children: [
              // Chapter thumbnail / cover (dimmed when read)
              Opacity(
                opacity: isRead ? 0.38 : 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 54,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 0.5,
                      ),
                    ),
                    child: (widget.coverUrl != null && widget.coverUrl!.isNotEmpty)
                        ? ProxiedImage(
                            imageUrl: widget.coverUrl!,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              '${chapter.chapterNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isRead
                                    ? AppColors.textMuted
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Chapter info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            chapter.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isRead
                                  ? AppColors.textMuted.withValues(alpha: 0.65)
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
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
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (isRead) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Sudah dibaca',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          chapter.relativeTime,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isRead
                                ? AppColors.textMuted.withValues(alpha: 0.5)
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Read indicator or chevron
              Icon(
                isRead
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
                color: isRead
                    ? AppColors.primary.withValues(alpha: 0.75)
                    : (_isHovered ? AppColors.textPrimary : AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
