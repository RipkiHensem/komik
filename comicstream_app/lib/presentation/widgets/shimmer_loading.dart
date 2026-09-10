import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Shimmer loading skeleton for various layouts
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.surface,
                AppColors.cardHover,
                AppColors.surface,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer loading grid for comic cards
class ComicCardShimmer extends StatelessWidget {
  const ComicCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: ShimmerLoading(borderRadius: 12),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerLoading(height: 12, width: 100),
                SizedBox(height: 6),
                ShimmerLoading(height: 10, width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of shimmer comic cards
class ComicGridShimmer extends StatelessWidget {
  final int count;

  const ComicGridShimmer({super.key, this.count = 8});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.62,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: count,
      itemBuilder: (context, index) => const ComicCardShimmer(),
    );
  }
}
