import 'package:flutter/widgets.dart';

import 'child_route_information_filter.dart';
import 'flow_route_status_scope.dart';
import 'route_information_reporter.dart';
import 'route_information_utils.dart';

/// A widget that associates [RouteInformation] with the provided [child]
/// subtree.
///
/// It serves two purposes:
/// - Reports the [routeInformation] to the parent flow or the platform when the
/// widget is in the top route.
/// - Forwards child route updates to the child only if the
/// [shouldForwardChildUpdates] predicate returns `true`.
class FlowRouteSubtree extends StatelessWidget {
  /// Creates a [FlowRouteSubtree].
  const FlowRouteSubtree({
    super.key,
    required this.child,
    required this.routeInformation,
    this.shouldForwardChildUpdates,
    this.isActive = true,
  });

  final Widget child;

  /// The route information to be reported to the parent flow or the
  /// platform.
  final RouteInformation routeInformation;

  /// Determines whether the child subtree should receive child route
  /// information updates from the parent flow.
  ///
  /// It's called with the most recently consumed route information by the
  /// parent flow.
  ///
  /// By default, [RouteInformationUtils.matchesUrlPattern] is used with the
  /// [routeInformation] as the pattern.
  final bool Function(RouteInformation parentConsumedRouteInformation)?
      shouldForwardChildUpdates;

  /// Whether the [routeInformation] should be reported to parent flows (or the
  /// platform) and back button events should be transmitted to the child
  /// subtree when the widget is in the top route.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);

    return FlowRouteStatusScope(
      isActive:
          isActive && (FlowRouteStatusScope.maybeOf(context)?.isActive ?? true),
      isTopRoute: route == null
          ? null
          : route.isCurrent &&
              (FlowRouteStatusScope.maybeOf(context)?.isTopRoute ?? true),
      child: RouteInformationReporter(
        routeInformation: routeInformation,
        child: ChildRouteInformationFilter(
          shouldForwardChildUpdates: shouldForwardChildUpdates ??
              (routeInformation) =>
                  routeInformation.matchesUrlPattern(this.routeInformation),
          child: child,
        ),
      ),
    );
  }
}
