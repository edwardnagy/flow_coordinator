import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'flow_navigator.dart';

/// A [RouterDelegate] that implements [FlowNavigator] to manage a stack of
/// pages within a flow coordinator.
final class FlowRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteInformation>
    implements FlowNavigator {
  FlowRouterDelegate({
    required List<Page> initialPages,
    required this.contextDescriptionProvider,
  }) : _pages = [...initialPages];

  final String Function() contextDescriptionProvider;

  List<Page> _pages;

  FlowNavigator? _parentFlowNavigator;

  @override
  final GlobalKey<NavigatorState>? navigatorKey = GlobalKey();

  void setParentFlowNavigator(
    FlowNavigator? parentFlowNavigator,
  ) =>
      _parentFlowNavigator = parentFlowNavigator;

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) =>
      SynchronousFuture(null);

  @override
  void push(Page page) {
    _pages = [..._pages, page];
    notifyListeners();
  }

  @override
  void replaceCurrentPage(Page page) {
    _pages = [..._pages.sublist(0, _pages.length - 1), page];
    notifyListeners();
  }

  @override
  void setPages(List<Page> pages) {
    _pages = [...pages];
    notifyListeners();
  }

  @override
  bool canPop() =>
      canPopInternally() || (_parentFlowNavigator?.canPop() ?? false);

  @override
  bool canPopInternally() => navigatorKey?.currentState?.canPop() ?? false;

  @override
  Future<bool> maybePop<T extends Object?>([T? result]) async {
    final internalPopResult = await maybePopInternally(result);
    if (internalPopResult) {
      return true;
    }
    final parentPopResult = await _parentFlowNavigator?.maybePop(result);
    if (parentPopResult == true) {
      return true;
    }
    return false;
  }

  @override
  Future<bool> maybePopInternally<T extends Object?>([T? result]) =>
      navigatorKey?.currentState?.maybePop(result) ?? Future.value(false);

  @override
  void pop<T extends Object?>([T? result]) {
    final parentFlowNavigator = _parentFlowNavigator;
    if (canPopInternally() || parentFlowNavigator == null) {
      popInternally(result);
    } else {
      parentFlowNavigator.pop(result);
    }
  }

  @override
  void popInternally<T extends Object?>([T? result]) =>
      navigatorKey?.currentState?.pop(result);

  @override
  Widget build(BuildContext context) {
    assert(
      _pages.isNotEmpty,
      'The pages list must not be empty.\n'
      '${contextDescriptionProvider()}',
    );

    return Navigator(
      key: navigatorKey,
      pages: _pages,
      onDidRemovePage: _pages.remove,
    );
  }
}
