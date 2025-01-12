import 'package:flutter/widgets.dart';

/// A widget that provides a [ChildBackButtonDispatcher] to its [builder] that
/// can be passed to a nested [Router] to handle back button events.
///
/// The [ChildBackButtonDispatcher] is created if the nearest [FocusScope] has
/// focus, ensuring back button events are handled by the topmost route only.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final oldBackButtonDispatcher = _backButtonDispatcher;
    oldBackButtonDispatcher?.parent.forget(oldBackButtonDispatcher);

    // Only handle back button events if the closest focus scope has focus.
    // Topmost routes are expected to request focus. If we don't have focus,
    // it means that another route is on top of this one, so this route (i.e.,
    // nested routers within this route) should not handle back button events.
    if (FocusScope.of(context).hasFocus) {
      final parentBackButtonDispatcher =
          Router.maybeOf(context)?.backButtonDispatcher;
      _backButtonDispatcher =
          parentBackButtonDispatcher?.createChildBackButtonDispatcher();
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
    return widget.builder(context, _backButtonDispatcher);
  }
}
