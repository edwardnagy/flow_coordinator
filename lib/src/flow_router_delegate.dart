import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'flow_configuration.dart';
import 'flow_navigator.dart';
import 'flow_route_handler.dart';

final class FlowRouterDelegate<T> extends RouterDelegate<FlowConfiguration<T>>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<FlowConfiguration<T>>
    implements FlowNavigator {
  FlowRouterDelegate({
    required List<Page> initialPages,
  }) : _pages = [...initialPages];

  List<Page> _pages;

  FlowNavigator? parentFlowNavigator;
  FlowRouteHandler<T>? flowRouteHandler;

  @override
  final GlobalKey<NavigatorState>? navigatorKey = GlobalKey();

  @override
  Future<void> setNewRoutePath(FlowConfiguration<T> configuration) {
    return flowRouteHandler?.setNewFlowRoute(configuration) ??
        SynchronousFuture(null);
  }

  @override
  Future<void> setInitialRoutePath(FlowConfiguration<T> configuration) {
    return flowRouteHandler?.setInitialFlowRoute(configuration) ??
        SynchronousFuture(null);
  }

  @override
  Future<void> setRestoredRoutePath(FlowConfiguration<T> configuration) {
    return flowRouteHandler?.setRestoredFlowRoute(configuration) ??
        SynchronousFuture(null);
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
    final canParentPop = parentFlowNavigator?.canPop();
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
    final parentPopResult = await parentFlowNavigator?.maybePop(result);
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
    final parentFlowNavigator = this.parentFlowNavigator;
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
    return Navigator(
      key: navigatorKey,
      pages: _pages,
      onDidRemovePage: _pages.remove,
    );
  }
}
