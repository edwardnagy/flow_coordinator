import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'consumable.dart';
import 'flow_route_information_provider.dart';
import 'identity_route_information_parser.dart';
import 'route_information_reporter_delegate.dart';

/// A router configuration for flow-based navigation in Flutter applications.
///
/// This class implements [RouterConfig] to provide a routing system that
/// organizes screens into user flows using the Flow Coordinator pattern.
///
/// Use [FlowCoordinatorRouter] as the `routerConfig` parameter of
/// [MaterialApp.router] or [CupertinoApp.router] to configure your app's
/// navigation:
///
/// ```dart
/// final _router = FlowCoordinatorRouter(
///   routeInformationReportingEnabled: true,
///   homeBuilder: (context) => const MyFlowCoordinator(),
/// );
///
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp.router(routerConfig: _router);
///   }
/// }
/// ```
///
/// See also:
///  * [FlowCoordinatorMixin], which manages navigation within individual flows.
///  * [FlowRouteScope], which controls route information reporting and filtering.
class FlowCoordinatorRouter implements RouterConfig<RouteInformation> {
  /// Creates a [FlowCoordinatorRouter].
  ///
  /// The [homeBuilder] parameter is required and provides the root flow
  /// coordinator for the application.
  ///
  /// The [backButtonDispatcher] parameter controls how back button events are
  /// dispatched. If not provided, a [RootBackButtonDispatcher] is used by
  /// default.
  ///
  /// The [routeInformationProvider] parameter provides route information to the
  /// router. If not provided, a [PlatformRouteInformationProvider] is created
  /// with the [initialUri] and [initialState].
  ///
  /// The [routeInformationParser] parameter is used to parse route information.
  /// Defaults to [IdentityRouteInformationParser] which passes route
  /// information through unchanged.
  ///
  /// The [initialUri] parameter specifies the initial route when the app starts.
  /// If not provided, the platform's default route is used.
  ///
  /// The [initialState] parameter specifies the initial state associated with
  /// the initial route.
  ///
  /// The [routeInformationReportingEnabled] parameter controls whether route
  /// information updates are reported to the platform (e.g., to update the
  /// browser URL). Defaults to `false`.
  FlowCoordinatorRouter({
    BackButtonDispatcher? backButtonDispatcher,
    RouteInformationProvider? routeInformationProvider,
    this.routeInformationParser = const IdentityRouteInformationParser(),
    Uri? initialUri,
    Object? initialState,
    this.routeInformationReportingEnabled = false,
    required this.homeBuilder,
  })  : backButtonDispatcher =
            backButtonDispatcher ?? RootBackButtonDispatcher(),
        routeInformationProvider = routeInformationProvider ??
            PlatformRouteInformationProvider(
              initialRouteInformation: RouteInformation(
                uri: _effectiveInitialUri(initialUri: initialUri),
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

  /// Whether route information reporting is enabled.
  ///
  /// When `true`, route information updates from nested flows are reported
  /// to the platform. This enables features like updating the browser URL
  /// in web applications or saving state restoration data.
  ///
  /// When `false`, route information updates are not reported, which can
  /// improve performance if these features are not needed.
  final bool routeInformationReportingEnabled;

  /// A builder function that creates the root flow coordinator widget.
  ///
  /// This function is called to build the root of the navigation tree.
  /// The returned widget should typically be a [StatefulWidget] that uses
  /// [FlowCoordinatorMixin] to manage navigation within the flow.
  final WidgetBuilder homeBuilder;

  static Uri _effectiveInitialUri({
    required Uri? initialUri,
  }) {
    final platformDefaultRouteName =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    final platformUri = platformDefaultRouteName == Navigator.defaultRouteName
        ? null
        : Uri.parse(platformDefaultRouteName);

    final effectiveUri =
        platformUri ?? initialUri ?? Uri.parse(Navigator.defaultRouteName);
    return effectiveUri;
  }

  /// Disposes of this router and releases its resources.
  ///
  /// This method should be called when the router is no longer needed,
  /// typically in the [State.dispose] method of the widget that created it.
  ///
  /// After calling [dispose], this router should not be used anymore.
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
