import 'package:flutter/widgets.dart';

import 'child_route_information_filter.dart';
import 'flow_route_status_scope.dart';
import 'route_information_reporter.dart';

// Public API
export 'child_route_information_filter.dart' show RouteInformationPredicate;

/// Wraps a subtree containing a flow coordinator, filtering and reporting route
/// information between the child and parent flows. Also controls whether the
/// child subtree is active and receives back button events.
class FlowSubtree extends StatelessWidget {
  /// Creates a [FlowSubtree].
  const FlowSubtree({
    super.key,
    this.routeInformation,
    this.shouldForwardChildUpdates,
    this.isActive = true,
    required this.child,
  });

  /// The route information to be reported to the parent flow or the
  /// platform. It's also used to filter child route information updates
  /// that are forwarded to the child subtree when [shouldForwardChildUpdates]
  /// is `null`.
  final RouteInformation? routeInformation;

  /// Determines if the child subtree should receive route information updates
  /// from the parent flow.
  ///
  /// This method is invoked with the latest route information consumed by the
  /// parent flow.
  ///
  /// If `null`, updates are forwarded only when they match [routeInformation].
  /// See [ChildRouteInformationFilter.pattern] for matching details.
  final RouteInformationPredicate? shouldForwardChildUpdates;

  /// Whether the subtree contains the currently active flow.
  ///
  /// If `true`, route information is reported and back button events are
  /// delivered to the child. If `false`, both are suppressed.
  final bool isActive;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final routeInformation = this.routeInformation;
    final shouldForwardChildUpdates = this.shouldForwardChildUpdates;

    var widget = child;

    if (shouldForwardChildUpdates != null) {
      widget = ChildRouteInformationFilter(
        shouldForwardChildUpdates: shouldForwardChildUpdates,
        child: widget,
      );
    } else if (routeInformation != null) {
      widget = ChildRouteInformationFilter.pattern(
        pattern: routeInformation,
        child: widget,
      );
    }

    if (routeInformation != null) {
      widget = RouteInformationReporter(
        routeInformation: routeInformation,
        child: widget,
      );
    }

    final route = ModalRoute.of(context);
    widget = FlowRouteStatusScope(
      isActive:
          isActive && (FlowRouteStatusScope.maybeOf(context)?.isActive ?? true),
      isTopRoute: route == null
          ? null
          : route.isCurrent &&
              (FlowRouteStatusScope.maybeOf(context)?.isTopRoute ?? true),
      child: widget,
    );

    return widget;
  }
}
