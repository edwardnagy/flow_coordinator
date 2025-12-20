import 'package:flutter/widgets.dart';
import 'flow_coordinator_mixin.dart';

/// The [FlowNavigator] provides methods to manage a navigation stack within
/// a flow coordinator (pushing, popping, and replacing pages).
///
/// Use [FlowNavigator.of] to retrieve the nearest [FlowNavigator] from the
/// widget tree, typically from within a screen widget. Use the `flowNavigator`
/// property from [FlowCoordinatorMixin] to access the navigator from within
/// a flow coordinator.
abstract interface class FlowNavigator {
  /// Returns the nearest [FlowNavigator] that encloses the given [context].
  ///
  /// Throws a [FlutterError] if no [FlowNavigator] is found in the widget tree.
  static FlowNavigator of(BuildContext context, {bool listen = false}) {
    final navigatorScope = listen
        ? context.dependOnInheritedWidgetOfExactType<FlowNavigatorScope>()
        : context.getInheritedWidgetOfExactType<FlowNavigatorScope>();
    if (navigatorScope == null) {
      throw FlutterError(
        '''
FlowNavigator.of() called with a context that does not contain a FlowNavigatorScope.

This happens if no FlowCoordinatorState is found above this widget in the widget tree.

The context used was: $context
''',
      );
    }
    return navigatorScope.flowNavigator;
  }

  /// Returns the nearest [FlowNavigator] that encloses the given [context],
  /// or null if no [FlowNavigator] is found.
  static FlowNavigator? maybeOf(BuildContext context, {bool listen = false}) {
    final navigatorScope = listen
        ? context.dependOnInheritedWidgetOfExactType<FlowNavigatorScope>()
        : context.getInheritedWidgetOfExactType<FlowNavigatorScope>();
    return navigatorScope?.flowNavigator;
  }

  /// Pushes the given [page] onto the navigator's stack.
  void push(Page page);

  /// Sets the navigator's page history to the provided list of [pages].
  void setPages(List<Page> pages);

  /// Replaces the current page (top of the stack) with the given [page].
  void replaceCurrentPage(Page page);

  /// Returns whether this navigator or any of its ancestor navigators from the
  /// widget tree can pop.
  bool canPop();

  /// Returns whether this navigator can pop.
  ///
  /// Behaves like [Navigator.canPop].
  bool canPopInternally();

  /// Attempts to pop this navigator or any of its ancestor navigators from the
  /// widget tree.
  ///
  /// Returns true if a navigator was popped, otherwise false.
  Future<bool> maybePop<T extends Object?>([T? result]);

  /// Attempts to pop this navigator.
  ///
  /// Returns true if this navigator was popped, otherwise false.
  ///
  /// Behaves like [Navigator.maybePop].
  Future<bool> maybePopInternally<T extends Object?>([T? result]);

  /// Pops the closest navigator in the widget tree that can pop. If no
  /// navigator can pop, the root navigator is popped.
  void pop<T extends Object?>([T? result]);

  /// Pops this navigator.
  ///
  /// Behaves like [Navigator.pop].
  void popInternally<T extends Object?>([T? result]);
}

class FlowNavigatorScope extends InheritedWidget {
  const FlowNavigatorScope({
    super.key,
    required this.flowNavigator,
    required super.child,
  });

  final FlowNavigator flowNavigator;

  @override
  bool updateShouldNotify(FlowNavigatorScope oldWidget) {
    return flowNavigator != oldWidget.flowNavigator;
  }
}
