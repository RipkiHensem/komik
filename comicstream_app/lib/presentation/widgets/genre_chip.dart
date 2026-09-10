import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Modern frosted capsule chip for categories and genres
class GenreChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const GenreChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<GenreChip> createState() => _GenreChipState();
}

class _GenreChipState extends State<GenreChip> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isActive => _isHovered || _isPressed;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

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
          scale: _isPressed ? 0.95 : (_isHovered ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected
                  ? null
                  : (_isActive ? AppColors.cardHover : AppColors.surface),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (_isActive
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : AppColors.glassBorder),
                width: 0.8,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : (_isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
                color: isSelected
                    ? Colors.white
                    : (_isActive ? AppColors.textPrimary : AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
