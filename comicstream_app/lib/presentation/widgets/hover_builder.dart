import 'package:flutter/material.dart';

/// A sleek, performant hover effect wrapper for Web & Desktop.
/// Adds a restrained press/hover transition for desktop and mobile widgets.
class HoverWidget extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, bool isHovered, Widget? child)? builder;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final Curve curve;
  final bool enableScale;
  final bool enableGlow;
  final Color? glowColor;
  final BorderRadius? borderRadius;
  final MouseCursor cursor;

  const HoverWidget({
    super.key,
    required this.child,
    this.builder,
    this.onTap,
    this.scale = 1.04,
    this.duration = const Duration(milliseconds: 180),
    this.curve = Curves.easeOutCubic,
    this.enableScale = true,
    this.enableGlow = false,
    this.glowColor,
    this.borderRadius,
    this.cursor = SystemMouseCursors.click,
  });

  /// Custom builder constructor for deep reactive styling on hover
  const HoverWidget.builder({
    super.key,
    required this.builder,
    this.child = const SizedBox.shrink(),
    this.onTap,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 180),
    this.curve = Curves.easeOutCubic,
    this.enableScale = false,
    this.enableGlow = false,
    this.glowColor,
    this.borderRadius,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<HoverWidget> createState() => _HoverWidgetState();
}

class _HoverWidgetState extends State<HoverWidget> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isActive => _isHovered || _isPressed;

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (widget.builder != null) {
      content = widget.builder!(context, _isActive, widget.child);
    } else {
      content = widget.child;
    }

    if (widget.enableScale) {
      final double targetScale = _isPressed
          ? (widget.scale > 1.0 ? 0.96 : widget.scale)
          : (_isHovered ? widget.scale : 1.0);

      content = AnimatedScale(
        scale: targetScale,
        duration: _isPressed ? const Duration(milliseconds: 100) : widget.duration,
        curve: widget.curve,
        child: content,
      );
    }

    final mouseRegion = MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: content,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: mouseRegion,
      );
    }

    return mouseRegion;
  }
}
