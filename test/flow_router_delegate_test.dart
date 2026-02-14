import 'package:flow_coordinator/src/flow_navigator.dart';
import 'package:flow_coordinator/src/flow_router_delegate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _appWithDelegate(FlowRouterDelegate delegate) => MaterialApp.router(
      routerConfig: RouterConfig<RouteInformation>(
        routerDelegate: delegate,
        routeInformationParser: const _PassthroughRouteInformationParser(),
        routeInformationProvider: PlatformRouteInformationProvider(
          initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
        ),
      ),
    );

void main() {
  group('FlowRouterDelegate', () {
    test('setNewRoutePath completes synchronously', () async {
      final delegate = FlowRouterDelegate(
        initialPages: const [MaterialPage(child: Text('Page 1'))],
        contextDescriptionProvider: () => 'Test context',
      );

      final routeInfo = RouteInformation(uri: Uri.parse('/new-route'));
      final future = delegate.setNewRoutePath(routeInfo);
      
      // Verify it returns a SynchronousFuture (completes immediately)
      expect(future, isA<SynchronousFuture<void>>());
      await future;
    });

    test('push adds page to navigation stack', () {
      final delegate = FlowRouterDelegate(
        initialPages: const [MaterialPage(child: Text('Page 1'))],
        contextDescriptionProvider: () => 'Test context',
      );

      var notified = false;
      delegate.addListener(() => notified = true);

      delegate.push(const MaterialPage(child: Text('Page 2')));

      expect(notified, true);
    });

    test('replaceCurrentPage replaces top page', () {
      final delegate = FlowRouterDelegate(
        initialPages: const [
          MaterialPage(child: Text('Page 1')),
          MaterialPage(child: Text('Page 2')),
        ],
        contextDescriptionProvider: () => 'Test context',
      );

      var notified = false;
      delegate.addListener(() => notified = true);

      delegate.replaceCurrentPage(const MaterialPage(child: Text('Page 3')));

      expect(notified, true);
    });

    test('setPages replaces all pages', () {
      final delegate = FlowRouterDelegate(
        initialPages: const [MaterialPage(child: Text('Page 1'))],
        contextDescriptionProvider: () => 'Test context',
      );

      var notified = false;
      delegate.addListener(() => notified = true);

      delegate.setPages(const [
        MaterialPage(child: Text('New Page 1')),
        MaterialPage(child: Text('New Page 2')),
      ]);

      expect(notified, true);
    });

    testWidgets('canPopInternally returns false when navigator cannot pop',
        (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: const [MaterialPage(child: Text('Page 1'))],
        contextDescriptionProvider: () => 'Test context',
      );

      await tester.pumpWidget(_appWithDelegate(delegate));

      expect(delegate.canPopInternally(), false);
    });

    testWidgets('canPopInternally returns true when navigator can pop',
        (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: const [
          MaterialPage(child: Text('Page 1')),
          MaterialPage(child: Text('Page 2')),
        ],
        contextDescriptionProvider: () => 'Test context',
      );

      await tester.pumpWidget(_appWithDelegate(delegate));

      expect(delegate.canPopInternally(), true);
    });

    testWidgets('canPop considers parent navigator', (tester) async {
      final parentDelegate = _TestFlowNavigator(canPopValue: true);
      final delegate = FlowRouterDelegate(
        initialPages: const [MaterialPage(child: Text('Page 1'))],
        contextDescriptionProvider: () => 'Test context',
      );
      delegate.setParentFlowNavigator(parentDelegate);

      await tester.pumpWidget(_appWithDelegate(delegate));

      expect(delegate.canPop(), true);
    });

    testWidgets('maybePop returns true when internal pop succeeds',
        (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: const [
          MaterialPage(child: Text('Page 1')),
          MaterialPage(child: Text('Page 2')),
        ],
        contextDescriptionProvider: () => 'Test context',
      );

      await tester.pumpWidget(_appWithDelegate(delegate));

      final result = await delegate.maybePop();
      expect(result, true);
    });

    testWidgets('maybePop returns false when cannot pop', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: const [MaterialPage(child: Text('Page 1'))],
        contextDescriptionProvider: () => 'Test context',
      );

      await tester.pumpWidget(_appWithDelegate(delegate));

      final result = await delegate.maybePop();
      expect(result, false);
    });

    testWidgets('maybePop delegates to parent when internal pop fails',
        (tester) async {
      final parentDelegate = _TestFlowNavigator(maybePopValue: true);
      final delegate = FlowRouterDelegate(
        initialPages: const [MaterialPage(child: Text('Page 1'))],
        contextDescriptionProvider: () => 'Test context',
      );
      delegate.setParentFlowNavigator(parentDelegate);

      await tester.pumpWidget(_appWithDelegate(delegate));

      final result = await delegate.maybePop();
      expect(result, true);
      expect(parentDelegate.maybePopCalled, true);
    });

    testWidgets('maybePopInternally returns false when navigator key is null',
        (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: const [MaterialPage(child: Text('Page 1'))],
        contextDescriptionProvider: () => 'Test context',
      );

      // Before pumping, navigator state is not initialized
      final result = await delegate.maybePopInternally();
      expect(result, false);
    });

    testWidgets('pop delegates to parent when cannot pop internally',
        (tester) async {
      final parentDelegate = _TestFlowNavigator(canPopValue: true);
      final delegate = FlowRouterDelegate(
        initialPages: const [MaterialPage(child: Text('Page 1'))],
        contextDescriptionProvider: () => 'Test context',
      );
      delegate.setParentFlowNavigator(parentDelegate);

      await tester.pumpWidget(_appWithDelegate(delegate));

      delegate.pop();
      expect(parentDelegate.popCalled, true);
    });

    testWidgets('pop pops internally when can pop internally', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: const [
          MaterialPage(child: Text('Page 1')),
          MaterialPage(child: Text('Page 2')),
        ],
        contextDescriptionProvider: () => 'Test context',
      );

      await tester.pumpWidget(_appWithDelegate(delegate));

      expect(find.text('Page 2'), findsOneWidget);

      delegate.pop();
      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsNothing);
    });

    testWidgets('popInternally pops page from navigator', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: const [
          MaterialPage(child: Text('Page 1')),
          MaterialPage(child: Text('Page 2')),
        ],
        contextDescriptionProvider: () => 'Test context',
      );

      await tester.pumpWidget(_appWithDelegate(delegate));

      delegate.popInternally();
      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
    });

    testWidgets('build asserts when pages list is empty', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: const [MaterialPage(child: Text('Page 1'))],
        contextDescriptionProvider: () => 'Test context description',
      );

      delegate.setPages([]);

      await tester.pumpWidget(_appWithDelegate(delegate));

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('onDidRemovePage is called when page is removed',
        (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: const [
          MaterialPage(key: ValueKey('page1'), child: Text('Page 1')),
          MaterialPage(key: ValueKey('page2'), child: Text('Page 2')),
        ],
        contextDescriptionProvider: () => 'Test context',
      );

      await tester.pumpWidget(_appWithDelegate(delegate));

      // Pop the top page
      delegate.pop();
      await tester.pumpAndSettle();

      // Verify page was removed from the list
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsNothing);
    });

  });
}

class _PassthroughRouteInformationParser
    extends RouteInformationParser<RouteInformation> {
  const _PassthroughRouteInformationParser();

  @override
  Future<RouteInformation> parseRouteInformation(
    RouteInformation routeInformation,
  ) =>
      SynchronousFuture(routeInformation);

  @override
  RouteInformation restoreRouteInformation(RouteInformation configuration) =>
      configuration;
}

class _TestFlowNavigator implements FlowNavigator {
  _TestFlowNavigator({
    this.canPopValue = false,
    this.maybePopValue = false,
  });

  final bool canPopValue;
  final bool maybePopValue;
  bool popCalled = false;
  bool maybePopCalled = false;

  @override
  bool canPop() => canPopValue;

  @override
  bool canPopInternally() => false;

  @override
  Future<bool> maybePop<T extends Object?>([T? result]) async {
    maybePopCalled = true;
    return maybePopValue;
  }

  @override
  Future<bool> maybePopInternally<T extends Object?>([T? result]) async =>
      false;

  @override
  void pop<T extends Object?>([T? result]) {
    popCalled = true;
  }

  @override
  void popInternally<T extends Object?>([T? result]) {}

  @override
  void push(Page page) {}

  @override
  void replaceCurrentPage(Page page) {}

  @override
  void setPages(List<Page> pages) {}
}
