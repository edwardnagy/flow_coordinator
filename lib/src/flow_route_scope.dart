import 'package:flutter/widgets.dart';

import 'child_route_information_filter.dart';
import 'flow_route_status_scope.dart';
import 'route_information_reporter.dart';

// Public APIs

export 'child_route_information_filter.dart' show RouteInformationPredicate;

/// A widget that wraps screen widgets within flows to control route information
/// and back button behavior.
///
/// This widget enables:
/// - Filtering route information updates between child and parent flows based
///   on the [shouldForwardChildUpdates] or [routeInformation] properties.
/// - Reporting the [routeInformation] to the parent flow when the route
///   [isActive] and is the top route in the navigation stack.
/// - Controlling whether the child subtree receives back button events via the
///   [isActive] property.
class FlowRouteScope extends StatelessWidget {
  /// Creates a [FlowRouteScope].
  const FlowRouteScope({
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

  /// A predicate that determines whether the child subtree should receive
  /// route information updates from the parent flow.
  ///
  /// This method is invoked with the latest route information consumed by the
  /// parent flow.
  ///
  /// If `null`, updates are forwarded only when they match [routeInformation].
  /// See [RouteInformationMatcher.matchesUrlPattern] for the matching
  /// criteria.
  final RouteInformationPredicate? shouldForwardChildUpdates;

  /// Whether the subtree contains the currently active flow.
  ///
  /// If `true`, route information is reported and back button events are
  /// delivered to the child. If `false`, both are suppressed.
  final bool isActive;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final routeInformation = this.routeInformation;

    final routeStatusScope = FlowRouteStatusScope.maybeOf(context);
    final isRouteActive =
        isActive && (routeStatusScope == null || routeStatusScope.isActive);
    final isTopRoute = (ModalRoute.of(context)?.isCurrent ?? false) &&
        (routeStatusScope == null || routeStatusScope.isTopRoute);

    return FlowRouteStatusScope(
      isActive: isRouteActive,
      isTopRoute: isTopRoute,
      child: RouteInformationReporter(
        routeInformation: routeInformation,
        child: ChildRouteInformationFilter(
          parentValueMatcher: shouldForwardChildUpdates ??
              (routeInformation == null
                  ? null
                  : (parentValue) =>
                      parentValue.matchesUrlPattern(routeInformation)),
          child: child,
        ),
      ),
    );
  }
}

@visibleForTesting
extension RouteInformationMatcher on RouteInformation {
  /// Whether this route matches the given [pattern].
  ///
  /// A match occurs if:
  /// - The path segments in [pattern] appear in this URI in the same order,
  /// starting from the beginning of the path.
  /// - All query parameters in [pattern] are present and match those in this
  /// URI.
  /// - The fragment in [pattern] is either empty or matches this URI's
  /// fragment.
  /// - The state matches the pattern’s state, using [stateMatcher] if provided.
  /// If omitted, states are considered equal if they are identical, or if
  /// the pattern's state is `null`.
  bool matchesUrlPattern(
    RouteInformation pattern, {
    bool Function(Object? state, Object? patternState)? stateMatcher,
  }) {
    final isPathMatching =
        pattern.uri.pathSegments.length <= uri.pathSegments.length &&
            pattern.uri.pathSegments.asMap().entries.every(
                  (patternEntry) =>
                      patternEntry.value == uri.pathSegments[patternEntry.key],
                );
    final isQueryMatching = pattern.uri.queryParameters.entries.every(
      (patternEntry) =>
          uri.queryParameters[patternEntry.key] == patternEntry.value,
    );
    final isFragmentMatching =
        pattern.uri.fragment.isEmpty || pattern.uri.fragment == uri.fragment;
    final isStateMatching = stateMatcher?.call(state, pattern.state) ??
        (pattern.state == null || state == pattern.state);

    return isPathMatching &&
        isQueryMatching &&
        isFragmentMatching &&
        isStateMatching;
  }
}
