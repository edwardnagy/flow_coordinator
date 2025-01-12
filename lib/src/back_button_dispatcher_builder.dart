import 'package:flutter/widgets.dart';

/// A widget that creates a child back button dispatcher with higher priority
/// than the parent dispatcher.
class BackButtonDispatcherBuilder extends StatefulWidget {
  const BackButtonDispatcherBuilder({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    ChildBackButtonDispatcher? backButtonDispatcher,
  ) builder;

  @override
  State<BackButtonDispatcherBuilder> createState() =>
      _BackButtonDispatcherBuilderState();
}

class _BackButtonDispatcherBuilderState
    extends State<BackButtonDispatcherBuilder> {
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
    return widget.builder(context, _backButtonDispatcher);
  }
}
