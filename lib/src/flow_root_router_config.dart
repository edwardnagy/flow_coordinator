import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'flow_route_information_provider.dart';

class FlowRouterConfig extends RouterConfig<RouteInformation> {
  FlowRouterConfig({
    required Widget home,
    String? initialRoutePath,
    FlowRouteInformationProvider? flowRouteInformationProvider,
    BackButtonDispatcher? backButtonDispatcher,
  }) : super(
          routerDelegate: FlowRootRouterDelegate(home: home),
          routeInformationProvider: flowRouteInformationProvider ??
              RootFlowRouteInformationProvider(
                initialRouteInformation: RouteInformation(
                  uri: Uri.parse(
                    _getInitialRouteName(initialRoutePath: initialRoutePath),
                  ),
                ),
              ),
          routeInformationParser: FlowRootRouteInformationParser(),
          backButtonDispatcher:
              backButtonDispatcher ?? RootBackButtonDispatcher(),
        );
}

// If window.defaultRouteName isn't '/', we should assume it was set
// intentionally via `setInitialRoute`, and should override whatever is in
// [widget.initialRoute].
String _getInitialRouteName({String? initialRoutePath}) {
  return WidgetsBinding.instance.platformDispatcher.defaultRouteName !=
          Navigator.defaultRouteName
      ? WidgetsBinding.instance.platformDispatcher.defaultRouteName
      : initialRoutePath ??
          WidgetsBinding.instance.platformDispatcher.defaultRouteName;
}

class FlowRootRouteInformationParser
    extends RouteInformationParser<RouteInformation> {
  @override
  Future<RouteInformation> parseRouteInformation(
    RouteInformation routeInformation,
  ) =>
      SynchronousFuture(routeInformation);

  @override
  RouteInformation restoreRouteInformation(RouteInformation configuration) =>
      configuration;
}

class FlowRootRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier {
  FlowRootRouterDelegate({
    required this.home,
  });

  final Widget home;

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) =>
      SynchronousFuture(null);

  @override
  Future<bool> popRoute() => SynchronousFuture(false);

  @override
  Widget build(BuildContext context) => home;
}
