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
    final indicatorColor = color ?? AppColors.primaryGreen;

    final child = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
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
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
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
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: AppDimensions.roundedDefault,
        border: Border.all(
          color: AppColors.borders,
          width: AppDimensions.cardBorderWidth,
        ),
      ),
    );
  }
}
