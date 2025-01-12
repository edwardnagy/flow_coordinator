import 'flow_configuration.dart';
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

  Future<void> setNewFlowRoute(FlowConfiguration<T> flowRoute) {
    if (flowRoute.childRouteInformation case final childRouteInformation?) {
      routeInformationProvider?.setChildValue(childRouteInformation);
    }
    return flowStateHandler.setNewFlowState(flowRoute.flowState);
  }

  Future<void> setInitialFlowRoute(FlowConfiguration<T> flowRoute) {
    if (flowRoute.childRouteInformation case final childRouteInformation?) {
      routeInformationProvider?.setChildValue(childRouteInformation);
    }
    return flowStateHandler.setInitialFlowState(flowRoute.flowState);
  }

  Future<void> setRestoredFlowRoute(FlowConfiguration<T> flowRoute) {
    if (flowRoute.childRouteInformation case final childRouteInformation?) {
      routeInformationProvider?.setChildValue(childRouteInformation);
    }
    return flowStateHandler.setRestoredFlowState(flowRoute.flowState);
  }
}
