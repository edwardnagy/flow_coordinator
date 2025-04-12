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
    initialRouteInformation: routeInformationProvider.value,
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
    _routerDelegate.dispose();
  }
}

class _RootFlowRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier {
  _RootFlowRouterDelegate({
    required this.homeBuilder,
    required RouteInformation initialRouteInformation,
  }) : _rootFlowRouteInformationProvider = _RootFlowRouteInformationProvider(
          initialRouteInformation: initialRouteInformation,
        ) {
    _routeInformationReporterDelegate.addListener(_onRouteInformationReported);
  }

  final WidgetBuilder homeBuilder;
  final _RootFlowRouteInformationProvider _rootFlowRouteInformationProvider;

  final _routeInformationReporterDelegate =
      RootRouteInformationReporterDelegate();

  RouteInformation? _currentRouteInformation;

  void _onRouteInformationReported() {
    final routeInformation =
        _routeInformationReporterDelegate.reportedRouteInformation;
    final isNewRouteInformation =
        routeInformation?.uri != _currentRouteInformation?.uri ||
            routeInformation?.state != _currentRouteInformation?.state;
    if (isNewRouteInformation) {
      _currentRouteInformation = routeInformation;
      notifyListeners();
    }
  }

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) {
    _currentRouteInformation = configuration;
    _rootFlowRouteInformationProvider.setChildValue(configuration);
    return SynchronousFuture(null);
  }

  @override
  Future<bool> popRoute() => SynchronousFuture(false);

  // TODO: Add logging for the reported route information.
  @override
  RouteInformation? get currentConfiguration => _currentRouteInformation;

  @override
  void dispose() {
    _rootFlowRouteInformationProvider.dispose();
    _routeInformationReporterDelegate
      ..removeListener(_onRouteInformationReported)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowRouteInformationProviderScope(
      _rootFlowRouteInformationProvider,
      child: RouteInformationReporterScope(
        _routeInformationReporterDelegate,
        child: Builder(builder: homeBuilder),
      ),
    );
  }
}

class _RootFlowRouteInformationProvider extends FlowRouteInformationProvider {
  _RootFlowRouteInformationProvider({
    required RouteInformation initialRouteInformation,
  }) : _childValueNotifier = ValueNotifier(Consumable(initialRouteInformation));

  final ValueNotifier<Consumable<RouteInformation>> _childValueNotifier;

  @override
  ValueListenable<Consumable<RouteInformation>> get childValueListenable =>
      _childValueNotifier;

  void setChildValue(RouteInformation routeInformation) {
    _childValueNotifier.value = Consumable(routeInformation);
  }

  void dispose() {
    _childValueNotifier.dispose();
  }
}
