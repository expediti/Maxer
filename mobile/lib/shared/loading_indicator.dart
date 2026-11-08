import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';

class RexamLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const RexamLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;

    final child = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      ),
    );

    if (message != null && message!.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: AppDimensions.space12),
          Text(
            message!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    }

    return Center(child: child);
  }
}

class RexamSkeletonCard extends StatelessWidget {
  final double height;
  final double? width;
  final EdgeInsetsGeometry margin;

  const RexamSkeletonCard({
    super.key,
    this.height = 120.0,
    this.width,
    this.margin = const EdgeInsets.only(bottom: AppDimensions.space12),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9);

    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: AppDimensions.roundedDefault,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
    );
  }
}

