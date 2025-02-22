import 'package:flutter/widgets.dart';

abstract interface class RouteInformationCombiner {
  static RouteInformationCombiner of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<RouteInformationCombinerScope>();
    if (scope == null) {
      throw FlutterError('''
RouteInformationCombiner.of() called with a context that does not contain a RouteInformationCombinerScope.
''');
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

    // Combine the URIs.
    var uri = Uri(
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

    // Prefix the URI with a slash if it doesn't have one.
    uri = uri.toString().startsWith('/') ? uri : Uri.parse('/$uri');

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
