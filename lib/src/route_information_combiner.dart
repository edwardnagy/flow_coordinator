import 'package:flutter/widgets.dart';

/// Defines how route information from nested flows is combined into a parent
/// flow's route information.
///
/// When using nested flow coordinators, each child flow may report its own
/// route information. The [RouteInformationCombiner] is responsible for merging
/// the child's route information with the current flow's route information to
/// produce a complete route that represents the full navigation hierarchy.
///
/// Use [RouteInformationCombiner.of] to retrieve the nearest combiner from the
/// widget tree. The default implementation is [DefaultRouteInformationCombiner],
/// which concatenates path segments, merges query parameters (with child
/// parameters overriding parent parameters), and uses the child's fragment.
///
/// You can provide a custom combiner by overriding the
/// [FlowCoordinatorMixin.routeInformationCombiner] property in your flow
/// coordinator.
abstract interface class RouteInformationCombiner {
  static RouteInformationCombiner of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<RouteInformationCombinerScope>();
    if (scope == null) {
      throw FlutterError.fromParts([
        ErrorSummary('No RouteInformationCombinerScope found.'),
        ...context.describeMissingAncestor(
          expectedAncestorType: RouteInformationCombinerScope,
        ),
      ]);
    }
    return scope.value;
  }

  /// Combines the [currentRouteInformation] with the [childRouteInformation]
  /// to produce a single [RouteInformation] that represents the complete route.
  ///
  /// The [currentRouteInformation] represents the route of the current flow,
  /// while the [childRouteInformation] represents the route of a nested child
  /// flow.
  RouteInformation combine({
    required RouteInformation currentRouteInformation,
    required RouteInformation childRouteInformation,
  });
}

/// Default implementation of [RouteInformationCombiner] that combines route
/// information by concatenating path segments and merging query parameters.
///
/// This combiner performs the following operations:
/// - **Path segments**: Concatenates the current flow's path segments with the
///   child flow's path segments.
/// - **Query parameters**: Merges query parameters from both routes, with the
///   child's parameters overriding the current flow's parameters when there are
///   conflicts.
/// - **Fragment**: Uses the child flow's fragment if present, otherwise no
///   fragment.
/// - **State**: Uses the child flow's state.
///
/// Example:
/// ```dart
/// // Current route: /home?tab=books
/// // Child route: /123?view=details#reviews
/// // Combined result: /home/123?tab=books&view=details#reviews
/// ```
class DefaultRouteInformationCombiner implements RouteInformationCombiner {
  const DefaultRouteInformationCombiner();

  @override
  RouteInformation combine({
    required RouteInformation currentRouteInformation,
    required RouteInformation childRouteInformation,
  }) {
    final currentUri = currentRouteInformation.uri;
    final childUri = childRouteInformation.uri;
    final uri = Uri(
      pathSegments:
          currentUri.pathSegments.isEmpty && childUri.pathSegments.isEmpty
              ? null
              : [
                  ...currentUri.pathSegments,
                  ...childUri.pathSegments,
                ],
      queryParameters: childUri.queryParameters.isEmpty
          ? null
          : {
              ...currentUri.queryParameters,
              ...childUri.queryParameters,
            },
      fragment: childUri.fragment.isEmpty ? null : childUri.fragment,
    );
    return RouteInformation(
      uri: uri,
      state: childRouteInformation.state,
    );
  }
}

class RouteInformationCombinerScope extends InheritedWidget {
  const RouteInformationCombinerScope(
    this.value, {
    super.key,
    required super.child,
  });

  final RouteInformationCombiner value;

  @override
  bool updateShouldNotify(RouteInformationCombinerScope oldWidget) =>
      value != oldWidget.value;
}
