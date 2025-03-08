import 'package:flutter/widgets.dart';

import 'child_route_information_filter.dart';
import 'flow_coordinator_state.dart';
import 'flow_route_status_scope.dart';
import 'route_information_reporter.dart';
import 'route_information_utils.dart';

// TODO: Fix docs for new name and functionality.
/// Associates the given [RouteInformation] with the provided [child] subtree.
///
/// More specifically, it has the following responsibilities:
/// - Reports the specified [RouteInformation] to the closest
/// [FlowCoordinatorState] ancestor when it is in a route where
/// [Route.isCurrent], and all its ancestors (in parent Navigator routes) are
/// also active.
/// - Filters route information updates passed to the child, ensuring only
/// updates that satisfy the [isMatchingRouteInformation] condition are
/// forwarded.
class FlowRouteSubtree extends StatelessWidget {
  const FlowRouteSubtree({
    super.key,
    required this.child,
    required this.routeInformation,
    this.isMatchingRouteInformation,
    this.isActive = true,
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

  /// Whether the provided [routeInformation] should be reported when this
  /// widget is in the current/top route.
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
          isMatchingRouteInformation: isMatchingRouteInformation ??
              (routeInformation) =>
                  routeInformation.matchesUrlPattern(this.routeInformation),
          child: child,
        ),
      ),
    );
  }
}
