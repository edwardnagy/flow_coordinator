import 'package:flutter/widgets.dart';

/// A widget that provides a [ChildBackButtonDispatcher] to its [builder] that
/// can be passed to a nested [Router] to handle back button events.
class FlowBackButtonDispatcherBuilder extends StatefulWidget {
  const FlowBackButtonDispatcherBuilder({super.key, required this.builder});

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

  bool _isTopRoute(BuildContext context) =>
      (FlowBackButtonDispatcherScope.maybeOf(context)?.isTopRoute ?? true) &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final backButtonDispatcher = _backButtonDispatcher;
    backButtonDispatcher?.parent.forget(backButtonDispatcher);
    if (_isTopRoute(context)) {
      _backButtonDispatcher = Router.maybeOf(context)
          ?.backButtonDispatcher
          ?.createChildBackButtonDispatcher();
      _backButtonDispatcher?.takePriority();
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
    return FlowBackButtonDispatcherScope(
      isTopRoute: _isTopRoute(context),
      child: Builder(
        builder: (context) => widget.builder(context, _backButtonDispatcher),
      ),
    );
  }
}

class FlowBackButtonDispatcherScope extends InheritedWidget {
  const FlowBackButtonDispatcherScope({
    super.key,
    required super.child,
    required this.isTopRoute,
  });

  final bool isTopRoute;

  static FlowBackButtonDispatcherScope? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FlowBackButtonDispatcherScope>();

  @override
  bool updateShouldNotify(FlowBackButtonDispatcherScope oldWidget) =>
      isTopRoute != oldWidget.isTopRoute;
}
