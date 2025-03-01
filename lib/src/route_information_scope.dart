import 'package:flutter/widgets.dart';

import 'flow_route_information_reporter.dart';
import 'route_information_combiner.dart';

class RouteInformationScope extends StatefulWidget {
  const RouteInformationScope({
    super.key,
    required this.child,
    required this.routeInformation,
    this.isActive = true,
  });

  final Widget child;
  final RouteInformation routeInformation;
  final bool isActive;

  @override
  State<RouteInformationScope> createState() => _RouteInformationScopeState();
}

class _RouteInformationScopeState extends State<RouteInformationScope> {
  late ChildFlowRouteInformationReporter _reporter;
  var _isReported = false;

  /// Returns whether the route information should be reported.
  bool _canReport(BuildContext context) =>
      widget.isActive &&
      (_RouteStateScope.maybeOf(context)?.canReport ?? true) &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  @override
  void didUpdateWidget(covariant RouteInformationScope oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.routeInformation != widget.routeInformation) {
      // We need to wait for the next frame to ensure that the new route is
      // focused before we report the route information.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (_canReport(context)) {
          _reporter.setCurrentRouteInformation(widget.routeInformation);
          _isReported = true;
        } else {
          _isReported = false;
        }
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

      final canReport = _canReport(context);
      if (canReport && !_isReported) {
        _reporter.setCurrentRouteInformation(widget.routeInformation);
        _isReported = true;
      } else if (!canReport) {
        _isReported = false;
      }
    });

    return _RouteStateScope(
      canReport: _canReport(context),
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
    required this.canReport,
  });

  final bool canReport;

  static _RouteStateScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RouteStateScope>();

  @override
  bool updateShouldNotify(_RouteStateScope oldWidget) =>
      oldWidget.canReport != canReport;
}
