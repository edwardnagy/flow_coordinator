import 'flow_route.dart';
import 'flow_route_information_provider.dart';
import 'flow_state_handler.dart';

/// TODO: Add documentation
class FlowRouteHandler<T> {
  FlowRouteHandler({
    required this.flowStateHandler,
    required this.routeInformationProvider,
  });

  final FlowStateHandler<T> flowStateHandler;
  final ChildFlowRouteInformationProvider? routeInformationProvider;

  Future<void> setNewFlowRoute(FlowRoute<T> flowRoute) {
    if (flowRoute.childRouteInformation case final childRouteInformation?) {
      routeInformationProvider?.setChildValue(childRouteInformation);
    }
    return flowStateHandler.setNewState(flowRoute.flowState);
  }

  Future<void> setInitialFlowRoute(FlowRoute<T> flowRoute) {
    if (flowRoute.childRouteInformation case final childRouteInformation?) {
      routeInformationProvider?.setChildValue(childRouteInformation);
    }
    return flowStateHandler.setInitialState(flowRoute.flowState);
  }

  Future<void> setRestoredFlowRoute(FlowRoute<T> flowRoute) {
    if (flowRoute.childRouteInformation case final childRouteInformation?) {
      routeInformationProvider?.setChildValue(childRouteInformation);
    }
    return flowStateHandler.setRestoredState(flowRoute.flowState);
  }
}
