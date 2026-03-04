import 'package:flow_coordinator/src/flow_navigator.dart';
import 'package:flow_coordinator/src/flow_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowRouterDelegate', () {
    testWidgets('push adds a page and notifies listeners', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('p1'), child: Text('Page 1')),
        ],
        contextDescriptionProvider: () => 'test context',
      );

      var notificationCount = 0;
      delegate.addListener(() => notificationCount++);

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: delegate,
          routeInformationParser: _MockRouteInformationParser(),
        ),
      );

      expect(find.text('Page 1'), findsOneWidget);

      delegate
          .push(const MaterialPage(key: ValueKey('p2'), child: Text('Page 2')));

      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);
      // Page 1 should be present but offstage
      expect(find.text('Page 1'), findsNothing);
      expect(find.text('Page 1', skipOffstage: false), findsOneWidget);
      expect(notificationCount, equals(1));
    });

    testWidgets('replaceCurrentPage replaces the top page', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('p1'), child: Text('Page 1')),
          const MaterialPage(key: ValueKey('p2'), child: Text('Page 2')),
        ],
        contextDescriptionProvider: () => 'test context',
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: delegate,
          routeInformationParser: _MockRouteInformationParser(),
        ),
      );

      expect(find.text('Page 2'), findsOneWidget);

      delegate.replaceCurrentPage(
        const MaterialPage(key: ValueKey('p3'), child: Text('Page 3')),
      );

      await tester.pumpAndSettle();

      expect(find.text('Page 3'), findsOneWidget);
      expect(find.text('Page 2'), findsNothing);
    });

    testWidgets('setPages updates entire stack', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: Text('Initial'))],
        contextDescriptionProvider: () => 'test context',
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: delegate,
          routeInformationParser: _MockRouteInformationParser(),
        ),
      );

      delegate.setPages([
        const MaterialPage(child: Text('New 1')),
        const MaterialPage(child: Text('New 2')),
      ]);

      await tester.pumpAndSettle();
      expect(find.text('New 2'), findsOneWidget);
    });

    testWidgets('build throws assertion error if pages empty', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: Text('Init'))],
        contextDescriptionProvider: () => 'test context',
      );

      // Force empty pages
      delegate.setPages([]);

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: delegate,
          routeInformationParser: _MockRouteInformationParser(),
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    group('Pop logic', () {
      testWidgets('canPop returns true if internal stack > 1', (tester) async {
        final delegate = FlowRouterDelegate(
          initialPages: [
            const MaterialPage(child: Text('1')),
            const MaterialPage(child: Text('2')),
          ],
          contextDescriptionProvider: () => 'test',
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
            routeInformationParser: _MockRouteInformationParser(),
          ),
        );

        expect(delegate.canPop(), isTrue);
        expect(delegate.canPopInternally(), isTrue);
      });

      testWidgets('canPop checks parent navigator if internal stack == 1',
          (tester) async {
        final parentNavigator = _MockFlowNavigator();
        final delegate = FlowRouterDelegate(
          initialPages: [const MaterialPage(child: Text('1'))],
          contextDescriptionProvider: () => 'test',
        );
        delegate.setParentFlowNavigator(parentNavigator);

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
            routeInformationParser: _MockRouteInformationParser(),
          ),
        );

        // Parent says yes
        parentNavigator.canPopResult = true;
        expect(delegate.canPop(), isTrue);
        expect(delegate.canPopInternally(), isFalse);

        // Parent says no
        parentNavigator.canPopResult = false;
        expect(delegate.canPop(), isFalse);
        expect(delegate.canPopInternally(), isFalse);
      });

      testWidgets('maybePop pops internally if possible', (tester) async {
        final delegate = FlowRouterDelegate(
          initialPages: [
            const MaterialPage(child: Text('1')),
            const MaterialPage(child: Text('2')),
          ],
          contextDescriptionProvider: () => 'test',
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
            routeInformationParser: _MockRouteInformationParser(),
          ),
        );

        // Verify initial state: 2 is visible, 1 is offstage
        expect(find.text('2'), findsOneWidget);
        expect(find.text('1'), findsNothing);
        expect(find.text('1', skipOffstage: false), findsOneWidget);

        final popped = await delegate.maybePop();
        expect(popped, isTrue);
        await tester.pumpAndSettle();
        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('maybePop calls parent if internal pop fails',
          (tester) async {
        final parentNavigator = _MockFlowNavigator();
        final delegate = FlowRouterDelegate(
          initialPages: [const MaterialPage(child: Text('1'))],
          contextDescriptionProvider: () => 'test',
        );
        delegate.setParentFlowNavigator(parentNavigator);

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
            routeInformationParser: _MockRouteInformationParser(),
          ),
        );

        // Parent success
        parentNavigator.maybePopResult = true;
        var result = await delegate.maybePop();
        expect(result, isTrue);
        expect(parentNavigator.maybePopCalled, isTrue);

        // Parent failure
        parentNavigator.maybePopCalled = false;
        parentNavigator.maybePopResult = false;
        result = await delegate.maybePop();
        expect(result, isFalse);
      });

      testWidgets('pop calls parent if internal pop not possible',
          (tester) async {
        final parentNavigator = _MockFlowNavigator();
        final delegate = FlowRouterDelegate(
          initialPages: [const MaterialPage(child: Text('1'))],
          contextDescriptionProvider: () => 'test',
        );
        delegate.setParentFlowNavigator(parentNavigator);

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
            routeInformationParser: _MockRouteInformationParser(),
          ),
        );

        delegate.pop();
        expect(parentNavigator.popCalled, isTrue);
      });

      testWidgets('pop pops internally if possible', (tester) async {
        final delegate = FlowRouterDelegate(
          initialPages: [
            const MaterialPage(child: Text('1')),
            const MaterialPage(child: Text('2')),
          ],
          contextDescriptionProvider: () => 'test',
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
            routeInformationParser: _MockRouteInformationParser(),
          ),
        );

        // Verify we have 2 pages
        expect(find.text('2'), findsOneWidget);
        expect(find.text('1'), findsNothing);
        expect(find.text('1', skipOffstage: false), findsOneWidget);

        // Pop should remove the top page
        delegate.pop();
        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('popInternally pops the internal stack', (tester) async {
        final delegate = FlowRouterDelegate(
          initialPages: [
            const MaterialPage(child: Text('1')),
            const MaterialPage(child: Text('2')),
          ],
          contextDescriptionProvider: () => 'test',
        );

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
            routeInformationParser: _MockRouteInformationParser(),
          ),
        );

        delegate.popInternally();
        await tester.pumpAndSettle();
        expect(find.text('1'), findsOneWidget);
      });
    });
  });
}

class _MockRouteInformationParser
    extends RouteInformationParser<RouteInformation> {
  @override
  Future<RouteInformation> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    return Future.value(routeInformation);
  }

  @override
  RouteInformation restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}

class _MockFlowNavigator implements FlowNavigator {
  bool canPopResult = false;
  bool maybePopResult = false;
  bool maybePopCalled = false;
  bool popCalled = false;

  @override
  void push(Page page) {}

  @override
  void setPages(List<Page> pages) {}

  @override
  void replaceCurrentPage(Page page) {}

  @override
  bool canPop() => canPopResult;

  @override
  bool canPopInternally() => false;

  @override
  Future<bool> maybePop<T extends Object?>([T? result]) {
    maybePopCalled = true;
    return Future.value(maybePopResult);
  }

  @override
  Future<bool> maybePopInternally<T extends Object?>([T? result]) =>
      Future.value(false);

  @override
  void pop<T extends Object?>([T? result]) {
    popCalled = true;
  }

  @override
  void popInternally<T extends Object?>([T? result]) {}
}
