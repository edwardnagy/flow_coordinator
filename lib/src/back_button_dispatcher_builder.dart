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

    final parent = Router.maybeOf(context)?.backButtonDispatcher;
    if (_backButtonDispatcher case final backButtonDispatcher?) {
      final previousParent = backButtonDispatcher.parent;
      if (parent != previousParent) {
        previousParent.forget(backButtonDispatcher);
        _backButtonDispatcher = parent?.createChildBackButtonDispatcher();
      }
    } else {
      _backButtonDispatcher = parent?.createChildBackButtonDispatcher();
    }
  }

  @override
  void dispose() {
    if (_backButtonDispatcher case final backButtonDispatcher?) {
      backButtonDispatcher.parent.forget(backButtonDispatcher);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _backButtonDispatcher?.takePriority();

    return widget.builder(context, _backButtonDispatcher);
  }
}
