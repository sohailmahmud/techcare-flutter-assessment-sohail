import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Custom page transitions for the app
class AppPageTransitions {
  static PageRouteBuilder<T> slideTransition<T>({
    required Widget page,
    RouteSettings? settings,
    SlideDirection direction = SlideDirection.fromRight,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AppConstants.pageTransition,
      reverseTransitionDuration: AppConstants.pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetTween = Tween<Offset>(
          begin: _getOffsetForDirection(direction),
          end: Offset.zero,
        );

        final slideAnimation = animation.drive(
          offsetTween.chain(CurveTween(curve: Curves.easeInOutCubic)),
        );

        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<T> fadeTransition<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AppConstants.pageTransition,
      reverseTransitionDuration: AppConstants.pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: Curves.easeInOut),
          ),
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<T> scaleTransition<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AppConstants.pageTransition,
      reverseTransitionDuration: AppConstants.pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween<double>(begin: 0.85, end: 1.0).chain(
              CurveTween(curve: Curves.easeInOutCubic),
            ),
          ),
          child: FadeTransition(
            opacity: animation.drive(
              CurveTween(curve: Curves.easeInOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static Route<T> modalBottomSheetWithBlur<T>({
    required Widget child,
    required BuildContext context,
    bool isScrollControlled = true,
    bool enableDrag = true,
  }) {
    return ModalBottomSheetRoute<T>(
      builder: (context) => child,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      transitionAnimationController: AnimationController(
        duration: AppConstants.modalTransition,
        vsync: Navigator.of(context),
      ),
      modalBarrierColor: Colors.black.withValues(alpha: 0.6),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    );
  }

  static Offset _getOffsetForDirection(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.fromLeft:
        return const Offset(-1.0, 0.0);
      case SlideDirection.fromRight:
        return const Offset(1.0, 0.0);
      case SlideDirection.fromTop:
        return const Offset(0.0, -1.0);
      case SlideDirection.fromBottom:
        return const Offset(0.0, 1.0);
    }
  }
}

enum SlideDirection {
  fromLeft,
  fromRight,
  fromTop,
  fromBottom,
}

/// Custom hero animation for FAB to form screen
class FABHeroRoute<T> extends PageRoute<T> {
  final Widget child;
  final String heroTag;

  FABHeroRoute({
    required this.child,
    required this.heroTag,
    RouteSettings? settings,
  }) : super(settings: settings);

  @override
  Color get barrierColor => Colors.transparent;

  @override
  String get barrierLabel => '';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => AppConstants.pageTransition;

  @override
  Duration get reverseTransitionDuration => AppConstants.pageTransition;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ),
      ),
      child: FadeTransition(
        opacity: animation.drive(
          CurveTween(curve: Curves.easeInOut),
        ),
        child: child,
      ),
    );
  }
}
