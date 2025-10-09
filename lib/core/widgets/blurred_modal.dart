import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Modal bottom sheet with backdrop blur effect
class BlurredModalBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;
  final bool isScrollControlled;
  final bool showDragHandle;

  const BlurredModalBottomSheet({
    super.key,
    required this.child,
    this.height,
    this.isScrollControlled = true,
    this.showDragHandle = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? height,
    bool isScrollControlled = true,
    bool showDragHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionAnimationController: AnimationController(
        duration: AppConstants.modalTransition,
        vsync: Navigator.of(context),
      ),
      builder: (context) => BlurredModalBottomSheet(
        height: height,
        isScrollControlled: isScrollControlled,
        showDragHandle: showDragHandle,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// Custom dialog with backdrop blur
class BlurredDialog extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool barrierDismissible;

  const BlurredDialog({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.barrierDismissible = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(24),
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: BlurredDialog(
          padding: padding,
          barrierDismissible: barrierDismissible,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
