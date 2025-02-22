import 'package:flutter/widgets.dart';

import 'flow_route_information_reporter.dart';
import 'route_information_combiner.dart';

class RouteInformationScope extends StatefulWidget {
  const RouteInformationScope({
    super.key,
    required this.routeInformation,
    required this.child,
  });

  final RouteInformation routeInformation;
  final Widget child;

  @override
  State<RouteInformationScope> createState() => _RouteInformationScopeState();
}

class _RouteInformationScopeState extends State<RouteInformationScope> {
  late ChildFlowRouteInformationReporter _reporter;
  var _isPreviouslyTopRoute = false;

  bool _isTopRoute(BuildContext context) =>
      (_RouteStateScope.maybeOf(context)?.isTopRoute ?? true) &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  @override
  void didUpdateWidget(covariant RouteInformationScope oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.routeInformation != widget.routeInformation) {
      // We need to wait for the next frame to ensure that the new route is
      // focused before we report the route information.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final isTopRoute = _isTopRoute(context);
        if (isTopRoute) {
          _reporter.setCurrentRouteInformation(widget.routeInformation);
        }
        _isPreviouslyTopRoute = isTopRoute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _reporter = ChildFlowRouteInformationReporter(
      parent: FlowRouteInformationReporter.of(context),
      routeInformationCombiner: RouteInformationCombiner.of(context),
    );

    // Wait for the next frame to ensure the parent's route information is set
    // in didUpdateWidget (if it was updated) before we report the route
    // information.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final isTopRoute = _isTopRoute(context);
      if (isTopRoute && !_isPreviouslyTopRoute) {
        _reporter.setCurrentRouteInformation(widget.routeInformation);
      }
      _isPreviouslyTopRoute = isTopRoute;
    });

    return _RouteStateScope(
      isTopRoute: _isTopRoute(context),
      child: FlowRouteInformationReporterScope(
        _reporter,
        child: widget.child,
      ),
    );
  }
}

class _RouteStateScope extends InheritedWidget {
  const _RouteStateScope({
    required super.child,
    required this.isTopRoute,
  });

  final bool isTopRoute;

  static _RouteStateScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RouteStateScope>();

  @override
  bool updateShouldNotify(_RouteStateScope oldWidget) =>
      oldWidget.isTopRoute != isTopRoute;
}
