import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'back_button_dispatcher_builder.dart';
import 'flow_navigator.dart';
import 'flow_navigator_scope.dart';
import 'flow_route.dart';
import 'flow_route_handler.dart';
import 'flow_route_information_provider.dart';
import 'flow_route_information_provider_builder.dart';
import 'flow_router_delegate.dart';
import 'flow_state_handler.dart';

// TODO: Add documentation
class FlowCoordinatorState<S extends StatefulWidget, T> extends State<S>
    implements FlowStateHandler<T>, RouteInformationProcessor {
  List<Page> get initialPages => [];

  FlowNavigator get flowNavigator => _routerDelegate;

  RouteInformationParser<FlowRoute<T>>? get routeInformationParser => null;

  /// The initial route information in case the parent flow doesn't provide any.
  RouteInformation get initialRouteInformation => RouteInformation(uri: Uri());

  late final _routerDelegate =
      FlowRouterDelegate<T>(initialPages: initialPages);

  @override
  Future<void> setNewState(T flowState) {
    return SynchronousFuture(null);
  }

  @override
  Future<void> setInitialState(T flowState) {
    return setNewState(flowState);
  }

  @override
  Future<void> setRestoredState(T flowState) {
    return setNewState(flowState);
  }

  @override
  RouteInformation? createRouteInformation({
    required RouteInformation childRouteInformation,
  }) {
    final currentConfiguration = _routerDelegate.currentConfiguration;
    if (currentConfiguration == null) return null;

    final currentFlowState = currentConfiguration.flowState;
    final currentRouteInformation =
        routeInformationParser?.restoreRouteInformation(
      FlowRoute(currentFlowState, childRouteInformation: childRouteInformation),
    );
    return currentRouteInformation;
  }

  // @override
  // void buildCurrentRouteInformation(
  //   RouteInformation routeInformation, {
  //   required RouteInformationReportingType type,
  // }) {
  //   final currentConfiguration = _routerDelegate.currentConfiguration;
  //   if (currentConfiguration == null) return;

  //   final currentFlowState = currentConfiguration.flowState;
  //   final currentRouteInformation =
  //       routeInformationParser?.restoreRouteInformation(
  //     FlowRoute(currentFlowState, childRouteInformation: routeInformation),
  //   );
  //   if (currentRouteInformation == null) return;

  //   Router.maybeOf(context)
  //       ?.routeInformationProvider
  //       ?.routerReportsNewRouteInformation(currentRouteInformation, type: type);
  // }

  @override
  void dispose() {
    _routerDelegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _routerDelegate.parentFlowNavigator = FlowNavigator.maybeOf(context);

    return FlowRouteInformationProviderBuilder(
      routeInformationProcessor: this,
      initialRouteInformation: initialRouteInformation,
      builder: (context, routeInformationProvider) {
        _routerDelegate.flowRouteHandler = FlowRouteHandler(
          flowStateHandler: this,
          routeInformationProvider: routeInformationProvider,
        );

        return BackButtonDispatcherBuilder(
          builder: (context, backButtonDispatcher) {
            return FlowNavigatorScope(
              flowNavigator: _routerDelegate,
              child: Router(
                routerDelegate: _routerDelegate,
                backButtonDispatcher: backButtonDispatcher,
                routeInformationParser: routeInformationParser,
                routeInformationProvider: routeInformationParser != null
                    ? routeInformationProvider
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
