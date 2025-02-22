import 'package:flutter/widgets.dart';

import 'route_information_combiner.dart';

abstract class FlowRouteInformationReporter {
  static FlowRouteInformationReporter of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<
        FlowRouteInformationReporterScope>();
    if (scope == null) {
      throw FlutterError(
        '''
FlowRouteInformationReporter.of() called with a context that does not contain a FlowRouteInformationReporterScope.

This happens if the routerConfig of WidgetsApp/MaterialApp/CupertinoApp is not set to FlowCoordinator.routerConfig.

The context used was: $context
''', // TODO: Double-check the error message
      );
    }
    return scope.value;
  }

  void childReportsRouteInformation(RouteInformation childRouteInformation);
}

class RootFlowRouteInformationReporter extends FlowRouteInformationReporter {
  RootFlowRouteInformationReporter({
    required this.routeInformationProvider,
  });

  final RouteInformationProvider routeInformationProvider;

  @override
  void childReportsRouteInformation(RouteInformation childRouteInformation) {
    // Prefix the URI with a slash if it doesn't have one.
    final uri = childRouteInformation.uri;
    final prefixedUri =
        uri.toString().startsWith('/') ? uri : Uri.parse('/$uri');
    final prefixedRouteInformation = RouteInformation(
      uri: prefixedUri,
      state: childRouteInformation.state,
    );

    routeInformationProvider
        .routerReportsNewRouteInformation(prefixedRouteInformation);
  }
}

class ChildFlowRouteInformationReporter extends FlowRouteInformationReporter {
  ChildFlowRouteInformationReporter({
    required this.parent,
    required this.routeInformationCombiner,
  });

  final FlowRouteInformationReporter parent;
  final RouteInformationCombiner routeInformationCombiner;

  late RouteInformation _currentRouteInformation;

  void setCurrentRouteInformation(RouteInformation routeInformation) {
    _currentRouteInformation = routeInformation;
    parent.childReportsRouteInformation(routeInformation);
  }

  @override
  void childReportsRouteInformation(RouteInformation childRouteInformation) {
    final routeInformation = routeInformationCombiner.combine(
      currentRouteInformation: _currentRouteInformation,
      childRouteInformation: childRouteInformation,
    );
    parent.childReportsRouteInformation(routeInformation);
  }
}

/// NOTE: Reporting happens on the route level, not the router level. Only the
/// top-most route should report route information.
class FlowRouteInformationReporterScope extends InheritedWidget {
  const FlowRouteInformationReporterScope(
    this.value, {
    super.key,
    required super.child,
  });

  final FlowRouteInformationReporter value;

  @override
  bool updateShouldNotify(
    FlowRouteInformationReporterScope oldWidget,
  ) =>
      value != oldWidget.value;
}
