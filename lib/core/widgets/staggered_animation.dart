import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Widget that provides staggered fade and slide animations for list items
class StaggeredListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration? delay;
  final Duration? duration;
  final Curve curve;
  final Offset slideOffset;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay,
    this.duration,
    this.curve = Curves.easeOutCubic,
    this.slideOffset = const Offset(0.3, 0),
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration ?? AppConstants.listItemAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // Start animation with stagger delay
    final delay =
        widget.delay ??
        Duration(
          milliseconds:
              widget.index * AppConstants.listItemAnimation.inMilliseconds,
        );

    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
        );
      },
    );
  }
}

/// Widget that provides staggered animations for a list of children
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration? itemDelay;
  final Duration? itemDuration;
  final Curve curve;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const StaggeredList({
    super.key,
    required this.children,
    this.itemDelay,
    this.itemDuration,
    this.curve = Curves.easeOutCubic,
    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    final staggeredChildren = children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;

      return StaggeredListItem(
        key: ValueKey(index),
        index: index,
        delay: itemDelay,
        duration: itemDuration,
        curve: curve,
        slideOffset: direction == Axis.vertical
            ? const Offset(0, 0.3)
            : const Offset(0.3, 0),
        child: child,
      );
    }).toList();

    if (direction == Axis.vertical) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: staggeredChildren,
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: staggeredChildren,
      );
    }
  }
}
