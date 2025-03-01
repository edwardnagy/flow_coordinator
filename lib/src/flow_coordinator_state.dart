import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'flow_back_button_dispatcher_builder.dart';
import 'flow_navigator.dart';
import 'flow_navigator_scope.dart';
import 'flow_route_information_provider.dart';
import 'flow_router_delegate.dart';
import 'route_information_combiner.dart';

// TODO: Add documentation
class FlowCoordinatorState<T extends StatefulWidget> extends State<T> {
  List<Page> get initialPages => [];

  FlowNavigator get flowNavigator => _routerDelegate;

  /// The initial route information in case the parent flow doesn't provide any.
  RouteInformation get initialRouteInformation => RouteInformation(uri: Uri());

  RouteInformationCombiner get routeInformationCombiner =>
      const DefaultRouteInformationCombiner();

  late final _routerDelegate = FlowRouterDelegate(initialPages: initialPages);

  late final _routeInformationProvider =
      ChildFlowRouteInformationProvider(initialValue: initialRouteInformation);

  /// Called when new route information is received from the platform or the
  /// parent flow. New pages can be pushed or set here using [flowNavigator].
  ///
  /// The returned route information will be forwarded to the nested flows.
  ///
  /// If the result can be computed synchronously, consider using a
  /// [SynchronousFuture] to avoid making the [Router] wait for the next
  /// microtask to schedule a build.
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    return SynchronousFuture(null);
  }

  /// Sets a new route information to handle by [onNewRouteInformation].
  void setNewRouteInformation(RouteInformation routeInformation) {
    onNewRouteInformation(routeInformation).then((childRouteInformation) {
      if (childRouteInformation != null) {
        _routeInformationProvider.setChildValue(childRouteInformation);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    setNewRouteInformation(initialRouteInformation);
    _routeInformationProvider.addListener(() {
      setNewRouteInformation(_routeInformationProvider.value);
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
