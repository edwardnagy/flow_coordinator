import 'package:flutter/widgets.dart';

import 'equatable_flow_state.dart';
import 'flow_configuration.dart';
import 'flow_route_information_reporter.dart';

class FlowStateScope<T extends EquatableFlowState?> extends StatefulWidget {
  const FlowStateScope({
    super.key,
    required this.flowState,
    required this.child,
  });

  final T flowState;
  final Widget child;

  @override
  State<FlowStateScope> createState() => _FlowStateScopeState<T>();
}

class _FlowStateScopeState<T extends EquatableFlowState?>
    extends State<FlowStateScope<T>> {
  late ChildFlowRouteInformationReporter _reporter;

  bool _isTopRoute(BuildContext context) =>
      (FlowRouteScope.maybeOf(context)?.isTopRoute ?? true) &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    assert(
      Router.of(context).routeInformationParser
          is RouteInformationParser<FlowConfiguration<T>>,
      'Could not find a RouteInformationParser<FlowConfiguration<$T>> above '
      'this FlowStateReporterScope.',
    );
    _reporter = ChildFlowRouteInformationReporter<T>(
      parent: FlowRouteInformationReporter.of(context),
      routeInformationParser: Router.of(context).routeInformationParser
          as RouteInformationParser<FlowConfiguration<T>>,
    );

    // Wait for the next frame because the parent widget might be updating the
    // flow state in [didUpdateWidget] and we want to ensure that the parent
    // widget's flow state is set before we report the flow state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_isTopRoute(context)) {
        _reporter.setFlowState(widget.flowState);
      }
    });
  }

  @override
  void didUpdateWidget(FlowStateScope<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final (oldState, newState) = (oldWidget.flowState, widget.flowState);
    final isStateChanged = ((oldState == null) != (newState == null)) ||
        (oldState != null && newState != null && !oldState.isEqualTo(newState));

    if (isStateChanged) {
      // We need to wait for the next frame to ensure that the new route is
      // focused before we report the new flow state.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (_isTopRoute(context)) {
          _reporter.setFlowState(widget.flowState);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlowRouteScope(
      isTopRoute: _isTopRoute(context),
      child: FlowRouteInformationReporterScope(
        _reporter,
        child: widget.child,
      ),
    );
  }
}

class FlowRouteScope extends InheritedWidget {
  const FlowRouteScope({
    super.key,
    required super.child,
    required this.isTopRoute,
  });

  static FlowRouteScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlowRouteScope>();

  final bool isTopRoute;

  @override
  bool updateShouldNotify(FlowRouteScope oldWidget) =>
      isTopRoute != oldWidget.isTopRoute;
}
