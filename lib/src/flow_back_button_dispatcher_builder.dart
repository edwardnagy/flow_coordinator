import 'package:flutter/widgets.dart';

import 'flow_route_status_scope.dart';

/// A widget that provides a [ChildBackButtonDispatcher] to its [builder] that
/// can be passed to a nested [Router] to handle back button events.
class FlowBackButtonDispatcherBuilder extends StatefulWidget {
  const FlowBackButtonDispatcherBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(
    BuildContext context,
    ChildBackButtonDispatcher? backButtonDispatcher,
  ) builder;

  @override
  State<FlowBackButtonDispatcherBuilder> createState() =>
      _FlowBackButtonDispatcherBuilderState();
}

class _FlowBackButtonDispatcherBuilderState
    extends State<FlowBackButtonDispatcherBuilder> {
  ChildBackButtonDispatcher? _backButtonDispatcher;

  bool _isEnabled(BuildContext context) =>
      (FlowRouteStatusScope.maybeOf(context)?.isActive ?? true) &&
      (FlowRouteStatusScope.maybeOf(context)?.isTopRoute ?? true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final backButtonDispatcher = _backButtonDispatcher;
    backButtonDispatcher?.parent.forget(backButtonDispatcher);

    if (_isEnabled(context)) {
      _backButtonDispatcher = Router.maybeOf(context)
          ?.backButtonDispatcher
          ?.createChildBackButtonDispatcher();
      _backButtonDispatcher?.takePriority();
    } else {
      _backButtonDispatcher = null;
    }
  }

  @override
  void dispose() {
    final backButtonDispatcher = _backButtonDispatcher;
    backButtonDispatcher?.parent.forget(backButtonDispatcher);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _backButtonDispatcher);
  }
}
