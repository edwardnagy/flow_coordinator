import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'flow_back_button_dispatcher_builder.dart';
import 'flow_configuration.dart';
import 'flow_navigator.dart';
import 'flow_navigator_scope.dart';
import 'flow_route_handler.dart';
import 'flow_route_information_provider_builder.dart';
import 'flow_router_delegate.dart';
import 'flow_state_handler.dart';

// TODO: Add documentation
class FlowCoordinatorState<S extends StatefulWidget, T> extends State<S>
    implements FlowStateHandler<T> {
  List<Page> get initialPages => [];

  FlowNavigator get flowNavigator => _routerDelegate;

  RouteInformationParser<FlowConfiguration<T>>? get routeInformationParser =>
      null;

  /// The initial route information in case the parent flow doesn't provide any.
  RouteInformation get initialRouteInformation => RouteInformation(uri: Uri());

  late final _routerDelegate =
      FlowRouterDelegate<T>(initialPages: initialPages);

  @override
  Future<void> setNewFlowState(T flowState) {
    return SynchronousFuture(null);
  }

  @override
  Future<void> setInitialFlowState(T flowState) {
    return setNewFlowState(flowState);
  }

  @override
  Future<void> setRestoredFlowState(T flowState) {
    return setNewFlowState(flowState);
  }

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

        return FlowBackButtonDispatcherBuilder(
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
