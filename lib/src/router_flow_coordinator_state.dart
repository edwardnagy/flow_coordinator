import 'package:flutter/widgets.dart';

abstract class RouterFlowCoordinatorState<T extends StatefulWidget, C>
    extends State<T> {
  ChildBackButtonDispatcher? _defaultBackButtonDispatcher;

  RouterConfig<C> get routerConfig;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (routerConfig.backButtonDispatcher == null) {
      // Create a default back button dispatcher if not provided
      final newParentBackButtonDispatcher =
          Router.of(context).backButtonDispatcher;
      final defaultBackButtonDispatcher = _defaultBackButtonDispatcher;
      if (defaultBackButtonDispatcher == null) {
        _defaultBackButtonDispatcher =
            newParentBackButtonDispatcher?.createChildBackButtonDispatcher();
      } else {
        final oldParentBackButtonDispatcher =
            defaultBackButtonDispatcher.parent;
        if (oldParentBackButtonDispatcher != newParentBackButtonDispatcher) {
          oldParentBackButtonDispatcher.forget(defaultBackButtonDispatcher);
          _defaultBackButtonDispatcher =
              newParentBackButtonDispatcher?.createChildBackButtonDispatcher();
        }
      }
    }
  }

  @override
  void dispose() {
    final defaultBackButtonDispatcher = _defaultBackButtonDispatcher;
    defaultBackButtonDispatcher?.parent.forget(defaultBackButtonDispatcher);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_defaultBackButtonDispatcher case final defaultBackButtonDispatcher?) {
      if (routerConfig.backButtonDispatcher == null) {
        // Take priority if no custom back button dispatcher is provided
        defaultBackButtonDispatcher.takePriority();
      } else {
        // Forget default back button dispatcher if custom back button dispatcher is provided
        defaultBackButtonDispatcher.parent.forget(defaultBackButtonDispatcher);
        _defaultBackButtonDispatcher = null;
      }
    }

    return Router.withConfig(
      config: RouterConfig<C>(
        routerDelegate: routerConfig.routerDelegate,
        backButtonDispatcher:
            routerConfig.backButtonDispatcher ?? _defaultBackButtonDispatcher,
        routeInformationProvider: routerConfig.routeInformationProvider,
        routeInformationParser: routerConfig.routeInformationParser,
      ),
    );
  }
}
