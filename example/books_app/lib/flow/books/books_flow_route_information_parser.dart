part of 'books_flow_coordinator.dart';

class BooksFlowRouteInformationParser
    extends RouteInformationParser<FlowRoute<BooksFlowState>> {
  @override
  Future<FlowRoute<BooksFlowState>> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    // Get category from query parameters
    final bookId = routeInformation.uri.pathSegments.firstOrNull;
    final categoryParamValue = routeInformation.uri.queryParameters['category'];
    final category = categoryParamValue == null
        ? null
        : BookCategory.values.firstWhere(
            (category) => category.toQueryParamValue() == categoryParamValue,
          );

    final flowState = BooksFlowState(
      category: category,
      bookId: bookId,
    );
    final childRouteInformation = RouteInformation(
      uri: Uri(
        pathSegments: routeInformation.uri.pathSegments.skip(1),
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
    FlowRoute<BooksFlowState> configuration,
  ) {
    final state = configuration.flowState;
    final bookPathSegments = [
      if (state.bookId case final bookId?) bookId,
    ];
    final bookQueryParameters = {
      if (state.category case final category?)
        'category': category.toQueryParamValue(),
    };

    final queryParameters = {
      ...bookQueryParameters,
      ...?configuration.childRouteInformation?.uri.queryParameters,
    };

    return RouteInformation(
      uri: Uri(
        pathSegments: [
          ...bookPathSegments,
          ...?configuration.childRouteInformation?.uri.pathSegments
        ],
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      ),
      state: configuration.childRouteInformation?.state,
    );
  }
}

extension on BookCategory {
  String toQueryParamValue() => switch (this) {
        BookCategory.fiction => 'fiction',
        BookCategory.romance => 'romance',
        BookCategory.biography => 'biography',
      };
}
