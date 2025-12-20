import 'package:flutter/widgets.dart';

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

  RouteInformation combine({
    required RouteInformation currentRouteInformation,
    required RouteInformation childRouteInformation,
  });
}

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
