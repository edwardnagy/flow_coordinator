import 'package:flutter/widgets.dart';

/// Defines how route information from a parent flow and a child flow are
/// combined into a single route.
///
/// This interface is used to control how nested flows contribute to the
/// overall route information that is reported to the platform (e.g., for
/// updating the browser URL or saving state restoration data).
///
/// The default implementation is [DefaultRouteInformationCombiner], which
/// merges path segments, query parameters, and fragments hierarchically.
/// Custom implementations can be provided by overriding the
/// `routeInformationCombiner` property in [FlowCoordinatorMixin].
abstract interface class RouteInformationCombiner {
  /// Returns the nearest [RouteInformationCombiner] that encloses the given
  /// [context].
  ///
  /// Throws a [FlutterError] if no [RouteInformationCombiner] is found in the
  /// widget tree.
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

  /// Combines the [currentRouteInformation] from a parent flow with the
  /// [childRouteInformation] from a child flow into a single route.
  ///
  /// The returned [RouteInformation] represents the combined route that will
  /// be reported to the platform or to ancestor flows.
  RouteInformation combine({
    required RouteInformation currentRouteInformation,
    required RouteInformation childRouteInformation,
  });
}

/// The default implementation of [RouteInformationCombiner].
///
/// This combiner merges route information from parent and child flows by:
/// - Concatenating path segments from both routes in order (parent first, then
/// child).
/// - Merging query parameters, with child parameters overriding parent
/// parameters when keys conflict.
/// - Using the child's fragment if present, otherwise no fragment.
/// - Using the child's state.
///
/// For example, if the parent route is `/home` with query `?tab=books` and the
/// child route is `/details/123` with query `?page=2`, the combined route will
/// be `/home/details/123?tab=books&page=2`.
class DefaultRouteInformationCombiner implements RouteInformationCombiner {
  /// Creates a [DefaultRouteInformationCombiner].
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
