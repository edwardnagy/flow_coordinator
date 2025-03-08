import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'flow_back_button_dispatcher_builder.dart';
import 'flow_navigator.dart';
import 'flow_navigator_scope.dart';
import 'flow_route_information_provider.dart';
import 'flow_router_delegate.dart';
import 'route_information_combiner.dart';

/// Manages navigation and route information within a flow-based navigation
/// structure.
///
/// This stateful widget acts as a coordinator for handling route updates,
/// managing route information propagation, and ensuring correct navigation
/// behavior within a flow-based navigation hierarchy.
class FlowCoordinatorState<T extends StatefulWidget> extends State<T> {
  /// The initial list of pages for this flow.
  ///
  /// Can be overridden to provide specific initial pages.
  List<Page> get initialPages => [];

  /// Provides access to the [FlowNavigator] for this flow.
  FlowNavigator get flowNavigator => _routerDelegate;

  /// The initial route information used when no parent flow provides route
  /// data.
  RouteInformation get initialRouteInformation => RouteInformation(uri: Uri());

  /// Defines how route information is combined within this flow when nested
  /// flows report their route information.
  RouteInformationCombiner get routeInformationCombiner =>
      const DefaultRouteInformationCombiner();

  late final _routerDelegate = FlowRouterDelegate(initialPages: initialPages);

  late final _routeInformationProvider =
      ChildFlowRouteInformationProvider(initialValue: initialRouteInformation);

  /// Handles incoming route information from the platform or parent flow.
  ///
  /// This method allows new pages to be pushed or set using [flowNavigator].
  /// The returned [RouteInformation], if non-null, will be forwarded to nested
  /// flows.
  ///
  /// Consider using a [SynchronousFuture] if the result can be computed
  /// synchronously to avoid waiting for the next microtask to schedule the
  /// build.
  Future<RouteInformation?> handleNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    return SynchronousFuture(null);
  }

  /// Updates the current route information.
  void setNewRouteInformation(RouteInformation routeInformation) {
    _routeInformationProvider.value = routeInformation;
  }

  /// Processes changes in route information and propagates updates to child
  /// flows.
  void _processNewRouteInformation(RouteInformation routeInformation) {
    handleNewRouteInformation(routeInformation).then((childRouteInformation) {
      if (childRouteInformation != null) {
        _routeInformationProvider.setChildValue(childRouteInformation);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Initialize with the current route information and set up listeners.
    _processNewRouteInformation(_routeInformationProvider.value);
    _routeInformationProvider.addListener(() {
      _processNewRouteInformation(_routeInformationProvider.value);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final parentNavigator = FlowNavigator.maybeOf(context, listen: true);
    _routerDelegate.setParentFlowNavigator(parentNavigator);

    final parentProvider = FlowRouteInformationProvider.maybeOf(context);
    _routeInformationProvider.registerParentProvider(parentProvider);
  }

  @override
  void dispose() {
    _routeInformationProvider.dispose();
    _routerDelegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowBackButtonDispatcherBuilder(
      builder: (context, backButtonDispatcher) {
        return FlowRouteInformationProviderScope(
          _routeInformationProvider,
          child: RouteInformationCombinerScope(
            routeInformationCombiner,
            child: FlowNavigatorScope(
              flowNavigator: _routerDelegate,
              child: Router(
                routerDelegate: _routerDelegate,
                backButtonDispatcher: backButtonDispatcher,
              ),
            ),
          ),
        );
      },
    );
  }
}
