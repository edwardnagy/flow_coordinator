import 'package:flutter/widgets.dart';

import 'flow_route_status_scope.dart';
import 'route_information_combiner.dart';
import 'route_information_reporter_delegate.dart';

/// A widget that reports the provided [routeInformation] to the parent
/// [RouteInformationReporterDelegate] when the route is active and is the top
/// route in the navigation stack, as determined by the ancestor
/// [FlowRouteStatusScope] widget.
///
/// If [routeInformation] is `null`, no route information is reported.
class RouteInformationReporter extends StatefulWidget {
  /// Creates a [RouteInformationReporter].
  const RouteInformationReporter({
    super.key,
    required this.routeInformation,
    required this.child,
  });

  /// The route information to report, or `null` if nothing should be reported.
  final RouteInformation? routeInformation;

  /// The widget below this widget in the tree.
  final Widget child;

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

    final newRouteInformation = widget.routeInformation;
    if (newRouteInformation != null &&
        newRouteInformation != oldWidget.routeInformation) {
      // We need to wait for the next frame to ensure that the new route status
      // is set to know if we can report the route information.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Report the new route information if the route status allows it.
        if (_canReport(context)) {
          _delegate.setCurrentRouteInformation(newRouteInformation);
          _isReported = true;
        } else {
          // Reset reported state if route information can't be reported to
          // allow reporting the route information when the conditions change.
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

    // Report the route information when the reporter delegate changes.
    final routeInformation = widget.routeInformation;
    if (routeInformation != null) {
      // Wait for the next frame to ensure the parent's route information is set
      // in [didUpdateWidget] (if it was updated) before we report the route
      // information, so that the combined route information is correct.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final canReport = _canReport(context);
        // Prevent reporting the same route information multiple times.
        if (canReport && !_isReported) {
          _delegate.setCurrentRouteInformation(routeInformation);
          _isReported = true;
        } else if (!canReport) {
          // Reset reported state if route information can't be reported to
          // allow reporting the route information when the conditions change.
          _isReported = false;
        }
      });
    }

    return RouteInformationReporterScope(
      _delegate,
      child: widget.child,
    );
  }
}
