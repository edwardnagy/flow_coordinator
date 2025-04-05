import 'package:flutter/widgets.dart';

import 'route_information_combiner.dart';

abstract class RouteInformationReporterDelegate {
  static RouteInformationReporterDelegate of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<RouteInformationReporterScope>();
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

class RootRouteInformationReporterDelegate
    extends RouteInformationReporterDelegate {
  RootRouteInformationReporterDelegate({
    required this.routeInformationProvider,
  });

  final RouteInformationProvider routeInformationProvider;

  /// The route information pending to be reported.
  RouteInformation? _pendingRouteInformation;

  // TODO: Add logging for the reported route information.
  void _reportRouteInformation() {
    assert(
      _pendingRouteInformation != null,
      'Route information reporting task was scheduled but no route information '
      'is pending.',
    );
    routeInformationProvider
        .routerReportsNewRouteInformation(_pendingRouteInformation!);
    _pendingRouteInformation = null;
  }

  @override
  void childReportsRouteInformation(RouteInformation childRouteInformation) {
    // Prefix the URI with a slash if it doesn't have one.
    const prefix = '/';
    final uri = childRouteInformation.uri;
    final prefixedUri =
        uri.toString().startsWith(prefix) ? uri : Uri.parse('$prefix$uri');
    final prefixedRouteInformation = RouteInformation(
      uri: prefixedUri,
      state: childRouteInformation.state,
    );

    // Schedule the route information reporting task.
    final isReportingNotScheduled = _pendingRouteInformation == null;
    _pendingRouteInformation = prefixedRouteInformation;
    if (isReportingNotScheduled) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _reportRouteInformation(),
        debugLabel:
            'RootRouteInformationReporterDelegate.reportRouteInformation',
      );
    }
  }
}

class ChildRouteInformationReporterDelegate
    extends RouteInformationReporterDelegate {
  ChildRouteInformationReporterDelegate({
    required this.parent,
    required this.routeInformationCombiner,
  });

  final RouteInformationReporterDelegate parent;
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
class RouteInformationReporterScope extends InheritedWidget {
  const RouteInformationReporterScope(
    this.value, {
    super.key,
    required super.child,
  });

  final RouteInformationReporterDelegate value;

  @override
  bool updateShouldNotify(
    RouteInformationReporterScope oldWidget,
  ) =>
      value != oldWidget.value;
}
