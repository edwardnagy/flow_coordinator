import 'package:flutter/widgets.dart';

import 'flow_route_information_provider.dart';

/// A widget that creates a child flow route information provider from the
/// parent provider.
class FlowRouteInformationProviderBuilder extends StatefulWidget {
  const FlowRouteInformationProviderBuilder({
    super.key,
    required this.builder,
    required this.routeInformationProcessor,
    required this.initialRouteInformation,
  });

  final Widget Function(
    BuildContext context,
    ChildFlowRouteInformationProvider? routeInformationProvider,
  ) builder;
  final RouteInformationProcessor routeInformationProcessor;
  final RouteInformation initialRouteInformation;

  @override
  State<FlowRouteInformationProviderBuilder> createState() =>
      _FlowRouteInformationProviderBuilderState();
}

class _FlowRouteInformationProviderBuilderState
    extends State<FlowRouteInformationProviderBuilder> {
  ChildFlowRouteInformationProvider? _routeInformationProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final parent = Router.maybeOf(context)?.routeInformationProvider;
    if (parent is FlowRouteInformationProvider) {
      if (_routeInformationProvider case final previousProvider?) {
        final previousParent = previousProvider.parent;
        if (parent != previousParent) {
          // If the parent has changed, create a new child provider.
          _routeInformationProvider = ChildFlowRouteInformationProvider(
            parent: parent,
            routeInformationProcessor: widget.routeInformationProcessor,
            initialValue: previousProvider.value,
          );
          // Dispose of the previous provider.
          previousProvider.dispose();
        }
      } else {
        // If there is no previous provider, create a new child provider.
        _routeInformationProvider = ChildFlowRouteInformationProvider(
          parent: parent,
          routeInformationProcessor: widget.routeInformationProcessor,
          initialValue: widget.initialRouteInformation,
        );
      }
    } else {
      // If there is no parent, dispose of the current provider.
      _routeInformationProvider?.dispose();
      _routeInformationProvider = null;
    }
  }

  @override
  void dispose() {
    _routeInformationProvider?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _routeInformationProvider);
  }
}
