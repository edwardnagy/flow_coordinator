import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'flow_route_information_provider.dart';
import 'route_information_reporter_delegate.dart';
import 'identity_route_information_parser.dart';

class FlowRouterConfig extends RouterConfig<RouteInformation> {
  FlowRouterConfig({
    required WidgetBuilder builder,
    String? initialRoutePath,
    // TODO: Can this be a RouteInformationProvider?
    // TODO: Add option to disable the slash prefix for the URI.
    FlowRouteInformationProvider? flowRouteInformationProvider,
    BackButtonDispatcher? backButtonDispatcher,
  }) : super(
          // TODO: Dispose of the router delegate.
          routerDelegate: FlowRootRouterDelegate(builder: builder),
          routeInformationProvider: flowRouteInformationProvider ??
              RootFlowRouteInformationProvider(
                initialRouteInformation: RouteInformation(
                  uri: Uri.parse(
                    _getInitialRouteName(initialRoutePath: initialRoutePath),
                  ),
                ),
              ),
          routeInformationParser: const IdentityRouteInformationParser(),
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

class FlowRootRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier {
  FlowRootRouterDelegate({
    required this.builder,
  });

  final WidgetBuilder builder;

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) =>
      SynchronousFuture(null);

  @override
  Future<bool> popRoute() => SynchronousFuture(false);

  @override
  Widget build(BuildContext context) {
    final rootRouteInformationProvider =
        Router.of(context).routeInformationProvider;
    // TODO: Support null rootRouteInformationProvider or other than FlowRouteInformationProvider.
    assert(rootRouteInformationProvider is FlowRouteInformationProvider);
    return FlowRouteInformationProviderScope(
      rootRouteInformationProvider as FlowRouteInformationProvider,
      child: RouteInformationReporterScope(
        RootRouteInformationReporterDelegate(
          routeInformationProvider: rootRouteInformationProvider,
        ),
        child: Builder(builder: builder),
      ),
    );
  }
}
