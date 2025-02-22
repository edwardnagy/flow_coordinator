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

  ChildFlowRouteInformationProvider? _routeInformationProvider;

  /// Called when new route information is received from the platform or the
  /// parent flow.
  ///
  /// Navigates to the corresponding route based on the route information.
  /// The returned route information will be forwarded to the nested flows.
  ///
  /// If the result can be computed synchronously, consider using a
  /// [SynchronousFuture] to avoid making the [Router] wait for the next
  /// microtask to schedule a build.
  Future<RouteInformation?> setNewRoute(RouteInformation routeInformation) {
    return SynchronousFuture(null);
  }

  void _processRouteInformation(
    ChildFlowRouteInformationProvider provider,
    RouteInformation routeInformation,
  ) {
    // TODO: Add logging for the received route information per flow.
    setNewRoute(routeInformation).then((childRouteInformation) {
      if (childRouteInformation != null) {
        provider.setChildValue(childRouteInformation);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _routerDelegate.setParentFlowNavigator(
      FlowNavigator.maybeOf(context, listen: true),
    );

    final parentProvider = FlowRouteInformationProvider.maybeOf(context);
    if (parentProvider == null) {
      // If there is no parent, dispose of the current provider.
      _routeInformationProvider?.dispose();
      _routeInformationProvider = null;
    } else {
      final ChildFlowRouteInformationProvider? newProvider;
      if (_routeInformationProvider case final lastProvider?) {
        if (parentProvider == lastProvider.parent) {
          // Keep the previous provider if the parent hasn't changed.
          newProvider = null;
        } else {
          // Create a new child provider if the parent has changed.
          newProvider = ChildFlowRouteInformationProvider(
            parent: parentProvider,
            initialValue: lastProvider.value,
          );
          // Dispose of the previous provider.
          lastProvider.dispose();
        }
      } else {
        // If there is no previous provider, create a new child provider.
        newProvider = ChildFlowRouteInformationProvider(
          parent: parentProvider,
          initialValue: initialRouteInformation,
        );
      }
      if (newProvider case final newProvider?) {
        _routeInformationProvider = newProvider;
        _processRouteInformation(newProvider, newProvider.value);
        newProvider.addListener(
          () => _processRouteInformation(newProvider, newProvider.value),
        );
      }
    }
  }

  @override
  void dispose() {
    _routeInformationProvider?.dispose();
    _routerDelegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowBackButtonDispatcherBuilder(
      builder: (context, backButtonDispatcher) {
        Widget router = RouteInformationCombinerScope(
          routeInformationCombiner,
          child: FlowNavigatorScope(
            flowNavigator: _routerDelegate,
            child: Router(
              routerDelegate: _routerDelegate,
              backButtonDispatcher: backButtonDispatcher,
            ),
          ),
        );
        if (_routeInformationProvider case final routeInformationProvider?) {
          router = FlowRouteInformationProviderScope(
            routeInformationProvider,
            child: router,
          );
        }
        return router;
      },
    );
  }
}
