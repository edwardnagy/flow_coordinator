import 'package:flutter/widgets.dart';

// TODO: Add documentation
class FlowConfiguration<T> {
  const FlowConfiguration(
    this.flowState, {
    // required this.parsedRouteInformation,
    this.childRouteInformation,
  });

  final T flowState;

  // /// The parsed route information.
  // final RouteInformation parsedRouteInformation;
  final RouteInformation? childRouteInformation;
}
