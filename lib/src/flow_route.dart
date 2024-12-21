import 'package:flutter/widgets.dart';

// TODO: Add documentation
class FlowRoute<T> {
  const FlowRoute(
    this.flowState, {
    // required this.parsedRouteInformation,
    this.childRouteInformation,
  });

  final T flowState;

  // /// The parsed route information.
  // final RouteInformation parsedRouteInformation;
  final RouteInformation? childRouteInformation;
}
