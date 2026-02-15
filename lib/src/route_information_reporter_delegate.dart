import 'package:flutter/widgets.dart';

import 'route_information_combiner.dart';

/// A delegate that receives route information reports from child flows.
abstract class RouteInformationReporterDelegate {
  /// The nearest [RouteInformationReporterDelegate] in the widget tree above
  /// the given [context].
  ///
  /// Throws a [FlutterError] if no [RouteInformationReporterScope] is found.
  static RouteInformationReporterDelegate of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<RouteInformationReporterScope>();
    if (scope == null) {
      throw FlutterError.fromParts([
        ErrorSummary('No RouteInformationReporterScope found.'),
        ErrorHint(
          'Make sure the WidgetsApp/MaterialApp/CupertinoApp is set up with a '
          'FlowCoordinatorRouter.',
        ),
        ...context.describeMissingAncestor(
          expectedAncestorType: RouteInformationReporterScope,
        ),
      ]);
    }
    return scope.value;
  }

  /// Reports route information from a child flow to this delegate.
  void childReportsRouteInformation(RouteInformation childRouteInformation);
}

/// The root [RouteInformationReporterDelegate] that collects reported route
/// information and notifies listeners.
class RootRouteInformationReporterDelegate
    extends RouteInformationReporterDelegate with ChangeNotifier {
  /// The most recently reported route information, or `null` if nothing has
  /// been reported yet.
  RouteInformation? get reportedRouteInformation => _reportedRouteInformation;
  RouteInformation? _reportedRouteInformation;

  /// The route information pending to be reported.
  RouteInformation? _pendingRouteInformation;

  void _reportRouteInformation() {
    assert(
      _pendingRouteInformation != null,
      'Route information reporting task was scheduled but no route information '
      'is pending.',
    );
    _reportedRouteInformation = _pendingRouteInformation!;
    _pendingRouteInformation = null;
    if (hasListeners) {
      notifyListeners();
    }
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
      Future(_reportRouteInformation);
    }
  }
}

/// A child [RouteInformationReporterDelegate] that combines its own route
/// information with reports from nested children before forwarding to its
/// [parent].
class ChildRouteInformationReporterDelegate
    extends RouteInformationReporterDelegate {
  ChildRouteInformationReporterDelegate({
    required this.parent,
    required this.routeInformationCombiner,
  });

  final RouteInformationReporterDelegate parent;
  final RouteInformationCombiner routeInformationCombiner;

  RouteInformation? _currentRouteInformation;

  void setCurrentRouteInformation(RouteInformation routeInformation) {
    _currentRouteInformation = routeInformation;
    parent.childReportsRouteInformation(routeInformation);
  }

  @override
  void childReportsRouteInformation(RouteInformation childRouteInformation) {
    final routeInformation = routeInformationCombiner.combine(
      currentRouteInformation:
          _currentRouteInformation ?? RouteInformation(uri: Uri()),
      childRouteInformation: childRouteInformation,
    );
    parent.childReportsRouteInformation(routeInformation);
  }
}

/// An [InheritedWidget] that provides a [RouteInformationReporterDelegate] to
/// its descendants.
///
/// Reporting happens on the route level, not the router level. Only the
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
