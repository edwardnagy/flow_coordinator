import 'package:flutter/widgets.dart';

/// An [InheritedWidget] that provides the active and top-route status of a
/// flow route to its descendants.
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

  /// Whether the route is the top route in the navigator.
  final bool isTopRoute;

  /// The nearest [FlowRouteStatusScope] above the given [context], or `null`
  /// if none exists.
  static FlowRouteStatusScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlowRouteStatusScope>();

  @override
  bool updateShouldNotify(FlowRouteStatusScope oldWidget) =>
      oldWidget.isActive != isActive || oldWidget.isTopRoute != isTopRoute;
}
