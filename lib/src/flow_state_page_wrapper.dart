import 'package:flutter/widgets.dart';

// TODO: Add documentation
/// It's a wildcard type / special page.
@immutable
class FlowStatePageWrapper<T> extends Page {
  const FlowStatePageWrapper({
    required this.flowState,
    required this.page,
  });

  /// Represents the configuration of the route.
  ///
  /// Used to recreate the [RouteInformation] object for state restoration and
  /// web URL updates.
  final T flowState;
  final Page page;

  @override
  Route createRoute(BuildContext context) {
    throw UnsupportedError(
      'FlowStatePageWrapper is not meant to create routes directly. '
      'It is designed to wrap another page with a configuration. '
      'To access the wrapped page, use the `page` property.',
    );
  }
}
