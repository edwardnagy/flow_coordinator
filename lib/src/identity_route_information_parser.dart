import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A parser that returns the route information as is.
class IdentityRouteInformationParser
    extends RouteInformationParser<RouteInformation> {
  const IdentityRouteInformationParser();

  @override
  Future<RouteInformation> parseRouteInformation(
    RouteInformation routeInformation,
  ) =>
      SynchronousFuture(routeInformation);

  @override
  RouteInformation restoreRouteInformation(RouteInformation configuration) =>
      configuration;
}
