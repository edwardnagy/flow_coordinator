import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'consumable.dart';
import 'flow_route_information_provider.dart';
import 'identity_route_information_parser.dart';
import 'route_information_reporter_delegate.dart';

class FlowCoordinatorRouter implements RouterConfig<RouteInformation> {
  FlowCoordinatorRouter({
    required this.homeBuilder,
    BackButtonDispatcher? backButtonDispatcher,
    RouteInformationProvider? routeInformationProvider,
    this.routeInformationParser = const IdentityRouteInformationParser(),
    Uri? initialUri,
    Object? initialState,
    bool overridePlatformDefaultLocation = false,
  })  : assert(
          !overridePlatformDefaultLocation || initialUri != null,
          'initialUri must be set to override the platform default location.',
        ),
        backButtonDispatcher =
            backButtonDispatcher ?? RootBackButtonDispatcher(),
        routeInformationProvider = routeInformationProvider ??
            PlatformRouteInformationProvider(
              initialRouteInformation: RouteInformation(
                uri: _effectiveInitialUri(
                  overridePlatformDefaultLocation:
                      overridePlatformDefaultLocation,
                  initialUri: initialUri,
                ),
                state: initialState,
              ),
            );

  final WidgetBuilder homeBuilder;

  @override
  final BackButtonDispatcher backButtonDispatcher;

  @override
  final RouteInformationProvider routeInformationProvider;

  @override
  final RouteInformationParser<RouteInformation>? routeInformationParser;

  @override
  RouterDelegate<RouteInformation> get routerDelegate => _routerDelegate;
  late final _RootFlowRouterDelegate _routerDelegate = _RootFlowRouterDelegate(
    homeBuilder: homeBuilder,
    rootFlowRouteInformationProvider: _flowRouteInformationProvider,
    routeInformationReporterDelegate: _routeInformationReporterDelegate,
  );

  late final _RootFlowRouteInformationProvider _flowRouteInformationProvider =
      _RootFlowRouteInformationProvider(
    routeInformationProvider: routeInformationProvider,
  );

  late final RootRouteInformationReporterDelegate
      _routeInformationReporterDelegate = RootRouteInformationReporterDelegate(
    routeInformationProvider: routeInformationProvider,
  );

  static Uri _effectiveInitialUri({
    required bool overridePlatformDefaultLocation,
    required Uri? initialUri,
  }) {
    if (overridePlatformDefaultLocation) {
      // initialUri must not be null as asserted in the constructor.
      return initialUri!;
    }

    var platformDefaultUri = Uri.parse(
      WidgetsBinding.instance.platformDispatcher.defaultRouteName,
    );
    if (platformDefaultUri.hasEmptyPath) {
      platformDefaultUri = Uri(
        path: '/',
        queryParameters: platformDefaultUri.queryParameters,
      );
    }

    if (initialUri == null) {
      return platformDefaultUri;
    } else if (platformDefaultUri == Uri.parse('/')) {
      return initialUri;
    } else {
      return platformDefaultUri;
    }
  }

  void dispose() {
    _flowRouteInformationProvider.dispose();
    _routerDelegate.dispose();
  }
}

class _RootFlowRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier {
  _RootFlowRouterDelegate({
    required this.homeBuilder,
    required this.rootFlowRouteInformationProvider,
    required this.routeInformationReporterDelegate,
  });

  final WidgetBuilder homeBuilder;
  final _RootFlowRouteInformationProvider rootFlowRouteInformationProvider;
  final RootRouteInformationReporterDelegate routeInformationReporterDelegate;

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) =>
      SynchronousFuture(null);

  @override
  Future<bool> popRoute() => SynchronousFuture(false);

  @override
  Widget build(BuildContext context) {
    return FlowRouteInformationProviderScope(
      rootFlowRouteInformationProvider,
      child: RouteInformationReporterScope(
        routeInformationReporterDelegate,
        child: Builder(builder: homeBuilder),
      ),
    );
  }
}

class _RootFlowRouteInformationProvider extends FlowRouteInformationProvider {
  _RootFlowRouteInformationProvider({
    required this.routeInformationProvider,
  }) : _childValueNotifier =
            ValueNotifier(Consumable(routeInformationProvider.value)) {
    routeInformationProvider.addListener(_onRouteInformationChanged);
  }

  final RouteInformationProvider routeInformationProvider;
  final ValueNotifier<Consumable<RouteInformation>> _childValueNotifier;

  @override
  ValueListenable<Consumable<RouteInformation>> get childValueListenable =>
      _childValueNotifier;

  void _onRouteInformationChanged() {
    _childValueNotifier.value = Consumable(routeInformationProvider.value);
  }

  void dispose() {
    routeInformationProvider.removeListener(_onRouteInformationChanged);
    _childValueNotifier.dispose();
  }
}
