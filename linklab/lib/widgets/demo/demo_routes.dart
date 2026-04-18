import 'package:flutter/material.dart';

enum DemoRouteTransitionStyle { slide, modal }

PageRoute<T> buildDemoStageRoute<T>({
  required Widget page,
  RouteSettings? settings,
  DemoRouteTransitionStyle style = DemoRouteTransitionStyle.slide,
}) {
  final beginOffset = style == DemoRouteTransitionStyle.modal
      ? const Offset(0, 0.06)
      : const Offset(0.05, 0);

  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slideAnimation = Tween<Offset>(begin: beginOffset, end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          );
      final scaleAnimation = Tween<double>(begin: 0.985, end: 1).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        ),
      );
    },
  );
}

Future<T?> pushDemoStageRoute<T>(
  BuildContext context, {
  required Widget page,
  DemoRouteTransitionStyle style = DemoRouteTransitionStyle.slide,
  RouteSettings? settings,
}) {
  return Navigator.of(context).push<T>(
    buildDemoStageRoute<T>(page: page, style: style, settings: settings),
  );
}

Future<T?> replaceWithDemoStageRoute<T, TO>(
  BuildContext context, {
  required Widget page,
  DemoRouteTransitionStyle style = DemoRouteTransitionStyle.slide,
  RouteSettings? settings,
  TO? result,
}) {
  return Navigator.of(context).pushReplacement<T, TO>(
    buildDemoStageRoute<T>(page: page, style: style, settings: settings),
    result: result,
  );
}

Future<T?> pushAndRemoveUntilDemoStageRoute<T>(
  BuildContext context, {
  required Widget page,
  required RoutePredicate predicate,
  DemoRouteTransitionStyle style = DemoRouteTransitionStyle.slide,
  RouteSettings? settings,
}) {
  return Navigator.of(context).pushAndRemoveUntil<T>(
    buildDemoStageRoute<T>(page: page, style: style, settings: settings),
    predicate,
  );
}
