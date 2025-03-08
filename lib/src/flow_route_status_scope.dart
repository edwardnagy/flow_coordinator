import 'package:flutter/widgets.dart';

class FlowRouteStatusScope extends InheritedWidget {
  const FlowRouteStatusScope({
    super.key,
    required super.child,
    required this.isActive,
    required this.isTopRoute,
  });

  /// Whether the route can report its route information, or handle back button
  /// events.
  final bool isActive;

  /// Whether the route is the top route in the navigator. This is `null` if
  /// it cannot be determined.
  final bool? isTopRoute;

  static FlowRouteStatusScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlowRouteStatusScope>();

  @override
  bool updateShouldNotify(FlowRouteStatusScope oldWidget) =>
      oldWidget.isActive != isActive || oldWidget.isTopRoute != isTopRoute;
}
