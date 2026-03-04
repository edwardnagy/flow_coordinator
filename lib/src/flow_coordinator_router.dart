import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'consumable.dart';
import 'flow_route_information_provider.dart';
import 'identity_route_information_parser.dart';
import 'route_information_reporter_delegate.dart';

/// The router configuration for the app to use Flow Coordinators.
class FlowCoordinatorRouter implements RouterConfig<RouteInformation> {
  /// Creates a [FlowCoordinatorRouter].
  FlowCoordinatorRouter({
    BackButtonDispatcher? backButtonDispatcher,
    RouteInformationProvider? routeInformationProvider,
    this.routeInformationParser = const IdentityRouteInformationParser(),
    Uri? initialUri,
    Object? initialState,
    this.routeInformationReportingEnabled = true,
    required this.homeBuilder,
  })  : backButtonDispatcher =
            backButtonDispatcher ?? RootBackButtonDispatcher(),
        routeInformationProvider = routeInformationProvider ??
            PlatformRouteInformationProvider(
              initialRouteInformation: RouteInformation(
                uri: effectiveInitialUri(initialUri: initialUri),
                state: initialState,
              ),
            );

  @override
  final BackButtonDispatcher backButtonDispatcher;

  @override
  final RouteInformationProvider routeInformationProvider;

  @override
  final RouteInformationParser<RouteInformation>? routeInformationParser;

  @override
  RouterDelegate<RouteInformation> get routerDelegate => _routerDelegate;
  late final _RootFlowRouterDelegate _routerDelegate = _RootFlowRouterDelegate(
    initialRouteInformation: routeInformationProvider.value,
    reportingEnabled: routeInformationReportingEnabled,
    homeBuilder: homeBuilder,
  );

  /// Whether route information updates from nested flows are reported
  /// to the platform.
  ///
  /// This enables features like updating the browser URL in web applications or
  /// saving state restoration data.
  ///
  /// Defaults to `true`.
  final bool routeInformationReportingEnabled;

  /// The builder for the initial widget of the app, typically the root flow
  /// coordinator.
  final WidgetBuilder homeBuilder;

  /// The effective initial [Uri] computed from the given [initialUri] and
  /// the platform's default route name.
  ///
  /// The platform's default route name takes precedence over [initialUri] if
  /// it differs from [Navigator.defaultRouteName]. If neither is available,
  /// falls back to [Navigator.defaultRouteName].
  @visibleForTesting
  static Uri effectiveInitialUri({
    required Uri? initialUri,
    String? platformDefaultRouteNameOverride,
  }) {
    final platformDefaultRouteName = platformDefaultRouteNameOverride ??
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    Uri? platformUri;
    if (platformDefaultRouteName != Navigator.defaultRouteName) {
      platformUri = Uri.parse(platformDefaultRouteName);
    }

    final effectiveUri =
        platformUri ?? initialUri ?? Uri.parse(Navigator.defaultRouteName);
    return effectiveUri;
  }

  /// Disposes any resources created by this object.
  void dispose() {
    _routerDelegate.dispose();
  }
}

class _RootFlowRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier {
  _RootFlowRouterDelegate({
    required RouteInformation initialRouteInformation,
    required this.reportingEnabled,
    required this.homeBuilder,
  }) : _rootFlowRouteInformationProvider = _RootFlowRouteInformationProvider(
          initialRouteInformation: initialRouteInformation,
        ) {
    _routeInformationReporterDelegate.addListener(_onRouteInformationReported);
  }

  final _RootFlowRouteInformationProvider _rootFlowRouteInformationProvider;
  final bool reportingEnabled;
  final WidgetBuilder homeBuilder;

  final _routeInformationReporterDelegate =
      RootRouteInformationReporterDelegate();

  RouteInformation? _currentRouteInformation;

  void _onRouteInformationReported() {
    if (!reportingEnabled) {
      return;
    }
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
