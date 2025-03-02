import 'package:flutter/widgets.dart';

import 'child_route_information_filter.dart';
import 'flow_coordinator_state.dart';
import 'route_information_reporter.dart';
import 'route_information_utils.dart';

/// Associates the given [RouteInformation] with the provided [child] subtree.
///
/// More specifically, it has the following responsibilities:
/// - Reports the specified [RouteInformation] to the closest
/// [FlowCoordinatorState] ancestor when it is in a route where
/// [Route.isActive], and all its ancestors (in parent Navigator routes) are
/// also active.
/// - Filters route information updates passed to the child, ensuring only
/// updates that satisfy the [isMatchingRouteInformation] condition are
/// forwarded.
class RouteInformationScopedSubtree extends StatelessWidget {
  const RouteInformationScopedSubtree({
    super.key,
    required this.child,
    required this.routeInformation,
    this.isMatchingRouteInformation,
    this.reportingEnabled = true,
  });

  final Widget child;

  /// The route information to report when in the active route.
  final RouteInformation routeInformation;

  /// Determines whether a child [RouteInformation] update should be forwarded
  /// to the child. It is called with the current route information of the
  /// nearest [FlowCoordinatorState].
  ///
  /// If it returns true, the child receives the child [RouteInformation].
  /// Otherwise, the update is filtered out.
  ///
  /// It defaults to [RouteInformationUtils.matchesUrlPattern], using
  /// [routeInformation] as the matching pattern.
  final bool Function(RouteInformation routeInformation)?
      isMatchingRouteInformation;

  // Whether the [RouteInformation] should be reported when this widget is in
  // the active route.
  final bool reportingEnabled;

  @override
  Widget build(BuildContext context) {
    return RouteInformationReporter(
      routeInformation: routeInformation,
      enabled: reportingEnabled,
      child: ChildRouteInformationFilter(
        isMatchingRouteInformation: isMatchingRouteInformation ??
            (routeInformation) =>
                routeInformation.matchesUrlPattern(this.routeInformation),
        child: child,
      ),
    );
  }
}
