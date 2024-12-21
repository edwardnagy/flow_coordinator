part of 'authenticated_flow_coordinator.dart';

class AuthenticatedFlowRouteInformationParser
    extends RouteInformationParser<FlowRoute<AuthenticatedFlowState>> {
  @override
  Future<FlowRoute<AuthenticatedFlowState>> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    final pathSegments = routeInformation.uri.pathSegments;
    final AuthenticatedFlowState flowState;
    switch (pathSegments.firstOrNull) {
      case 'settings':
        flowState = const AuthenticatedFlowState(selectedTab: MainTab.settings);
      case 'books':
        flowState = const AuthenticatedFlowState(selectedTab: MainTab.books);
      case 'create-book':
        flowState = const AuthenticatedFlowState(isCreatingBook: true);
      default:
        flowState = const AuthenticatedFlowState();
    }

    final childRouteInformation = RouteInformation(
      uri: Uri(
        pathSegments: pathSegments.skip(1),
        queryParameters: routeInformation.uri.queryParameters,
      ),
      state: routeInformation.state,
    );

    return SynchronousFuture(
      FlowRoute(flowState, childRouteInformation: childRouteInformation),
    );
  }

  @override
  RouteInformation restoreRouteInformation(
    FlowRoute<AuthenticatedFlowState> configuration,
  ) {
    final flowState = configuration.flowState;
    final String mainPath;
    if (flowState.isCreatingBook) {
      mainPath = 'create-book';
    } else {
      mainPath = switch (flowState.selectedTab) {
        MainTab.books => 'books',
        MainTab.settings => 'settings',
      };
    }

    final queryParameters =
        configuration.childRouteInformation?.uri.queryParameters;

    return RouteInformation(
      uri: Uri(
        pathSegments: [
          mainPath,
          ...?configuration.childRouteInformation?.uri.pathSegments,
        ],
        queryParameters:
            queryParameters?.isEmpty == true ? null : queryParameters,
      ),
      state: configuration.childRouteInformation?.state,
    );
  }
}
