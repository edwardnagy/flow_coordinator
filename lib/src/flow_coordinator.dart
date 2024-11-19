import 'package:flutter/widgets.dart';

// TODO: Add documentation
abstract class FlowCoordinator extends StatefulWidget {
  const FlowCoordinator({super.key});

  @override
  FlowCoordinatorState createState();
}

abstract base class FlowCoordinatorState<T extends FlowCoordinator, C>
    extends State<T> {
  ChildBackButtonDispatcher? _backButtonDispatcher;

  RouterDelegate<C> get routerDelegate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Update the back button dispatcher when the parent dispatcher changes
    final newParentBackButtonDispatcher =
        Router.of(context).backButtonDispatcher;
    final backButtonDispatcher = _backButtonDispatcher;
    if (backButtonDispatcher == null) {
      _backButtonDispatcher =
          newParentBackButtonDispatcher?.createChildBackButtonDispatcher();
    } else {
      final oldParentBackButtonDispatcher = backButtonDispatcher.parent;
      if (oldParentBackButtonDispatcher != newParentBackButtonDispatcher) {
        oldParentBackButtonDispatcher.forget(backButtonDispatcher);
        _backButtonDispatcher =
            newParentBackButtonDispatcher?.createChildBackButtonDispatcher();
      }
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
    _backButtonDispatcher?.takePriority();

    return Router(
      routerDelegate: routerDelegate,
      backButtonDispatcher: _backButtonDispatcher,
    );
  }
}
