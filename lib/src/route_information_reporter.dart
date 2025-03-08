import 'package:flutter/widgets.dart';

import 'flow_route_status_scope.dart';
import 'route_information_combiner.dart';
import 'route_information_reporter_delegate.dart';

// TODO: Add documentation. Specify that FlowRouteStatusScope is needed for this
// to work.
class RouteInformationReporter extends StatefulWidget {
  const RouteInformationReporter({
    super.key,
    required this.child,
    required this.routeInformation,
  });

  final Widget child;
  final RouteInformation routeInformation;

  @override
  State<RouteInformationReporter> createState() =>
      _RouteInformationReporterState();
}

class _RouteInformationReporterState extends State<RouteInformationReporter> {
  late ChildRouteInformationReporterDelegate _delegate;
  var _isReported = false;

  bool _canReport(BuildContext context) =>
      (FlowRouteStatusScope.maybeOf(context)?.isActive ?? true) &&
      (FlowRouteStatusScope.maybeOf(context)?.isTopRoute ?? false);

  @override
  void didUpdateWidget(covariant RouteInformationReporter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.routeInformation != widget.routeInformation) {
      // We need to wait for the next frame to ensure that the new route is
      // focused before we report the route information.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (_canReport(context)) {
          _delegate.setCurrentRouteInformation(widget.routeInformation);
          _isReported = true;
        } else {
          _isReported = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _delegate = ChildRouteInformationReporterDelegate(
      parent: RouteInformationReporterDelegate.of(context),
      routeInformationCombiner: RouteInformationCombiner.of(context),
    );

    // Wait for the next frame to ensure the parent's route information is set
    // in [didUpdateWidget] (if it was updated) before we report the route
    // information.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final canReport = _canReport(context);
      if (canReport && !_isReported) {
        _delegate.setCurrentRouteInformation(widget.routeInformation);
        _isReported = true;
      } else if (!canReport) {
        _isReported = false;
      }
    });

    return RouteInformationReporterScope(
      _delegate,
      child: widget.child,
    );
  }
}
