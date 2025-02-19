import 'package:flutter/widgets.dart';

import 'flow_configuration.dart';

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

class ChildFlowRouteInformationReporter<T>
    extends FlowRouteInformationReporter {
  ChildFlowRouteInformationReporter({
    required this.parent,
    required this.routeInformationParser,
  });

  final FlowRouteInformationReporter parent;
  final RouteInformationParser<FlowConfiguration<T>> routeInformationParser;

  late T _flowState;

  void setFlowState(T flowState) {
    _flowState = flowState;
    final configuration = FlowConfiguration(flowState);
    final routeInformation =
        routeInformationParser.restoreRouteInformation(configuration);

    if (routeInformation != null) {
      parent.childReportsRouteInformation(routeInformation);
    }
  }

  @override
  void childReportsRouteInformation(RouteInformation childRouteInformation) {
    final configuration = FlowConfiguration(
      _flowState,
      childRouteInformation: childRouteInformation,
    );
    final routeInformation =
        routeInformationParser.restoreRouteInformation(configuration);

    if (routeInformation != null) {
      parent.childReportsRouteInformation(routeInformation);
    }
  }
}

class RootFlowRouteInformationReporter extends FlowRouteInformationReporter {
  RootFlowRouteInformationReporter({
    required this.routeInformationProvider,
  });

  final RouteInformationProvider routeInformationProvider;

  @override
  void childReportsRouteInformation(RouteInformation childRouteInformation) {
    routeInformationProvider
        .routerReportsNewRouteInformation(childRouteInformation);
  }
}

class FlowRouteInformationReporterScope extends InheritedWidget {
  const FlowRouteInformationReporterScope(
    this.value, {
    super.key,
    required super.child,
  });

  final FlowRouteInformationReporter value;

  static FlowRouteInformationReporterScope? maybeOf(
    BuildContext context,
  ) =>
      context.dependOnInheritedWidgetOfExactType<
          FlowRouteInformationReporterScope>();

  @override
  bool updateShouldNotify(
    FlowRouteInformationReporterScope oldWidget,
  ) =>
      value != oldWidget.value;
}
