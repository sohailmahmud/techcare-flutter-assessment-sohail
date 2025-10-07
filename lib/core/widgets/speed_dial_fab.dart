import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// Speed dial floating action button with expandable menu
class SpeedDialFAB extends StatefulWidget {
  final List<SpeedDialAction> actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData icon;
  final IconData? closeIcon;

  const SpeedDialFAB({
    super.key,
    required this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.icon = Icons.add,
    this.closeIcon,
  });

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isOpen)
          GestureDetector(
            onTap: _close,
            child: Container(
              color: AppColors.scrim,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),

        // Action buttons
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...widget.actions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              final delay = index * 50;

              return ScaleTransition(
                scale: CurvedAnimation(
                  parent: _scaleAnimation,
                  curve: Interval(
                    delay / (widget.actions.length * 50),
                    1.0,
                    curve: Curves.easeOut,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.space16),
                  child: _SpeedDialActionButton(
                    action: action,
                    heroTag: "speed_dial_action_$index",
                    onPressed: () {
                      _close();
                      action.onPressed();
                    },
                  ),
                ),
              );
            }),

            // Main FAB
            FloatingActionButton(
              heroTag: "speed_dial_main_fab",
              onPressed: _toggle,
              backgroundColor: widget.backgroundColor ?? AppColors.primary,
              foregroundColor: widget.foregroundColor ?? Colors.white,
              elevation: Spacing.elevation6,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: Icon(
                  _isOpen ? (widget.closeIcon ?? Icons.close) : widget.icon,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Speed dial action item
class SpeedDialAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SpeedDialAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });
}

/// Speed dial action button widget
class _SpeedDialActionButton extends StatelessWidget {
  final SpeedDialAction action;
  final VoidCallback onPressed;
  final String heroTag;

  const _SpeedDialActionButton({
    required this.action,
    required this.onPressed,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Material(
          elevation: Spacing.elevation2,
          borderRadius: BorderRadius.circular(Spacing.radiusS),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.space12,
              vertical: Spacing.space8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Spacing.radiusS),
            ),
            child: Text(
              action.label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        const SizedBox(width: Spacing.space12),

        // Button
        Material(
          elevation: Spacing.elevation4,
          shape: const CircleBorder(),
          color: action.backgroundColor ?? AppColors.primary,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(
                action.icon,
                color: action.foregroundColor ?? Colors.white,
                size: Spacing.iconS,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
