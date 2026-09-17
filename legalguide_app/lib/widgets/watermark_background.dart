import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WatermarkBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const WatermarkBackground({
    super.key,
    required this.child,
    this.opacity = 0.06,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Watermark Icon in background
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 260,
                  height: 260,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.gavel_rounded,
                      size: 240,
                      color: AppColors.accent,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // Screen Content Foreground
        child,
      ],
    );
  }
}
