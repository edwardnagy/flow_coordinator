import 'package:flow_coordinator/src/flow_navigator.dart';
import 'package:flow_coordinator/src/flow_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockFlowNavigator implements FlowNavigator {
  bool canPopResult = false;
  bool maybePopResult = false;
  bool popCalled = false;
  Object? popResult;

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
  Future<bool> maybePop<T extends Object?>([T? result]) =>
      Future.value(maybePopResult);

  @override
  Future<bool> maybePopInternally<T extends Object?>([T? result]) =>
      Future.value(false);

  @override
  void pop<T extends Object?>([T? result]) {
    popCalled = true;
    popResult = result;
  }

  @override
  void popInternally<T extends Object?>([T? result]) {}
}

void main() {
  group('FlowRouterDelegate', () {
    late FlowRouterDelegate delegate;

    setUp(() {
      delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'test context',
      );
    });

    tearDown(() {
      delegate.dispose();
    });

    test('push adds page and notifies listeners', () {
      var notified = false;
      delegate.addListener(() => notified = true);

      delegate.push(const MaterialPage(child: Text('pushed')));

      expect(notified, isTrue);
      expect(delegate.canPopInternally(), isFalse);
    });

    testWidgets('push adds page to navigator', (tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, child) {
            return Router(routerDelegate: delegate);
          },
        ),
      );

      delegate.push(const MaterialPage(child: Text('pushed')));
      await tester.pumpAndSettle();

      expect(find.text('pushed'), findsOneWidget);
      expect(delegate.canPopInternally(), isTrue);
    });

    test('replaceCurrentPage replaces last page and notifies', () {
      var notified = false;
      delegate.addListener(() => notified = true);

      delegate.replaceCurrentPage(
        const MaterialPage(child: Text('replaced')),
      );

      expect(notified, isTrue);
    });

    testWidgets('replaceCurrentPage replaces the page in navigator',
        (tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, child) {
            return Router(routerDelegate: delegate);
          },
        ),
      );

      delegate.replaceCurrentPage(
        const MaterialPage(child: Text('replaced')),
      );
      await tester.pumpAndSettle();

      expect(find.text('replaced'), findsOneWidget);
      expect(delegate.canPopInternally(), isFalse);
    });

    test('setPages replaces all pages and notifies', () {
      var notified = false;
      delegate.addListener(() => notified = true);

      delegate.setPages([
        const MaterialPage(child: Text('new')),
      ]);

      expect(notified, isTrue);
    });

    testWidgets('setPages replaces all pages in navigator', (tester) async {
      delegate.push(const MaterialPage(child: Text('second')));

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, child) {
            return Router(routerDelegate: delegate);
          },
        ),
      );
      expect(delegate.canPopInternally(), isTrue);

      delegate.setPages([
        const MaterialPage(child: Text('only page')),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('only page'), findsOneWidget);
      expect(delegate.canPopInternally(), isFalse);
    });

    test('setNewRoutePath completes without error', () async {
      // setNewRoutePath is a no-op that returns SynchronousFuture.
      // Verify it completes successfully.
      Object? error;
      try {
        await delegate.setNewRoutePath(
          RouteInformation(uri: Uri.parse('/test')),
        );
      } catch (e) {
        error = e;
      }
      expect(error, isNull);
    });

    test('setParentFlowNavigator sets parent', () {
      final parent = _MockFlowNavigator();
      delegate.setParentFlowNavigator(parent);
      // Verify by checking canPop delegates to parent
      parent.canPopResult = true;
      expect(delegate.canPop(), isTrue);
    });

    group('navigation methods', () {
      testWidgets('canPop returns false when no navigator state',
          (tester) async {
        expect(delegate.canPopInternally(), isFalse);
        expect(delegate.canPop(), isFalse);
      });

      testWidgets(
        'canPop delegates to parent when internal cannot pop',
        (tester) async {
          final parent = _MockFlowNavigator()..canPopResult = true;
          delegate.setParentFlowNavigator(parent);

          expect(delegate.canPop(), isTrue);
        },
      );

      testWidgets(
        'maybePopInternally returns false without navigator',
        (tester) async {
          final result = await delegate.maybePopInternally();
          expect(result, isFalse);
        },
      );

      testWidgets(
        'maybePop delegates to parent when internal fails',
        (tester) async {
          final parent = _MockFlowNavigator()..maybePopResult = true;
          delegate.setParentFlowNavigator(parent);

          final result = await delegate.maybePop();
          expect(result, isTrue);
        },
      );

      testWidgets(
        'maybePop returns false when both internal and parent fail',
        (tester) async {
          final parent = _MockFlowNavigator();
          delegate.setParentFlowNavigator(parent);

          final result = await delegate.maybePop();
          expect(result, isFalse);
        },
      );

      testWidgets(
        'pop delegates to parent when cannot pop internally '
        'and parent exists',
        (tester) async {
          final parent = _MockFlowNavigator();
          delegate.setParentFlowNavigator(parent);

          delegate.pop();

          expect(parent.popCalled, isTrue);
        },
      );
    });

    testWidgets('build creates Navigator with pages', (tester) async {
      delegate.push(const MaterialPage(child: Text('second page')));

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, child) {
            return delegate.build(context);
          },
        ),
      );

      expect(find.byType(Navigator), findsOneWidget);
      expect(delegate.canPopInternally(), isTrue);
      expect(find.text('second page'), findsOneWidget);
    });

    testWidgets(
      'build asserts when pages list is empty',
      (tester) async {
        final emptyDelegate = FlowRouterDelegate(
          initialPages: const [],
          contextDescriptionProvider: () => 'empty test',
        );

        expect(
          () => emptyDelegate.build(
            tester.element(find.byType(Container)),
          ),
          throwsAssertionError,
        );

        emptyDelegate.dispose();
      },
    );

    testWidgets(
      'maybePop returns true when internal pop succeeds',
      (tester) async {
        // Build the delegate so navigatorKey.currentState is available
        delegate.push(const MaterialPage(child: Text('second')));

        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            builder: (context, child) {
              return delegate.build(context);
            },
          ),
        );

        // Now we have 2 pages, so internal pop can succeed
        final result = await delegate.maybePop();
        expect(result, isTrue);
      },
    );

    testWidgets('popInternally pops the navigator', (tester) async {
      delegate.push(const MaterialPage(child: Text('second')));

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, child) {
            return delegate.build(context);
          },
        ),
      );

      expect(delegate.canPopInternally(), isTrue);
      delegate.popInternally();
      expect(delegate.canPopInternally(), isFalse);
    });

    testWidgets(
      'onDidRemovePage removes page on navigator pop',
      (tester) async {
        const page = MaterialPage(child: Text('second'));
        delegate.push(page);

        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            builder: (context, child) {
              return delegate.build(context);
            },
          ),
        );

        expect(delegate.canPopInternally(), isTrue);
        delegate.popInternally();
        await tester.pump();
        expect(delegate.canPopInternally(), isFalse);
      },
    );
  });
}
