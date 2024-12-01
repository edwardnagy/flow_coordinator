import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'flow_navigator.dart';
import 'flow_navigator_scope.dart';

final class NavigatorRouterDelegate<T> extends RouterDelegate<T>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<T>
    implements FlowNavigator {
  NavigatorRouterDelegate({required this.initialPages});

  final List<Page> initialPages;

  late List<Page> _pages = [...initialPages];
  FlowNavigator? _parentFlowNavigator;

  @override
  final GlobalKey<NavigatorState>? navigatorKey = GlobalKey();

  @override
  Future<void> setNewRoutePath(T configuration) {
    // TODO: implement setNewRoutePath
    return SynchronousFuture(null);
  }

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
  bool canPop() {
    final canPopInternally = this.canPopInternally();
    if (canPopInternally) {
      return true;
    }
    final canParentPop = _parentFlowNavigator?.canPop();
    if (canParentPop == true) {
      return true;
    }
    return false;
  }

  @override
  bool canPopInternally() {
    return navigatorKey?.currentState?.canPop() ?? false;
  }

  @override
  Future<bool> maybePop<S extends Object?>([S? result]) async {
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
  Future<bool> maybePopInternally<S extends Object?>([S? result]) {
    return navigatorKey?.currentState?.maybePop(result) ?? Future.value(false);
  }

  @override
  void pop<S extends Object?>([S? result]) {
    final parentFlowNavigator = _parentFlowNavigator;
    if (canPopInternally() || parentFlowNavigator == null) {
      popInternally(result);
    } else {
      parentFlowNavigator.pop(result);
    }
  }

  @override
  void popInternally<S extends Object?>([S? result]) {
    navigatorKey?.currentState?.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    _parentFlowNavigator = context
        .dependOnInheritedWidgetOfExactType<FlowNavigatorScope>()
        ?.navigator;

    return FlowNavigatorScope(
      navigator: this,
      child: Navigator(
        key: navigatorKey,
        pages: _pages,
        onDidRemovePage: _pages.remove,
      ),
    );
  }
}
