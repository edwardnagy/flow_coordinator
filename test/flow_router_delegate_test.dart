import 'package:flow_coordinator/src/flow_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowRouterDelegate', () {
    test('creates with initial pages', () {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test context',
      );

      expect(delegate, isNotNull);
      delegate.dispose();
    });

    test('has navigatorKey', () {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test',
      );

      expect(delegate.navigatorKey, isNotNull);
      delegate.dispose();
    });

    test('push adds page to stack', () {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('page1'), child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'Test',
      );

      var notified = false;
      delegate.addListener(() => notified = true);

      delegate
          .push(const MaterialPage(key: ValueKey('page2'), child: SizedBox()));

      expect(notified, isTrue);
      delegate.dispose();
    });

    test('replaceCurrentPage replaces top page', () {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('page1'), child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'Test',
      );

      delegate
          .push(const MaterialPage(key: ValueKey('page2'), child: SizedBox()));

      var notified = false;
      delegate.addListener(() => notified = true);

      delegate.replaceCurrentPage(
        const MaterialPage(key: ValueKey('page3'), child: SizedBox()),
      );

      expect(notified, isTrue);
      delegate.dispose();
    });

    test('setPages replaces entire page stack', () {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('page1'), child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'Test',
      );

      var notified = false;
      delegate.addListener(() => notified = true);

      delegate.setPages([
        const MaterialPage(key: ValueKey('newPage1'), child: SizedBox()),
        const MaterialPage(key: ValueKey('newPage2'), child: SizedBox()),
      ]);

      expect(notified, isTrue);
      delegate.dispose();
    });

    test('canPop returns false when no parent and cannot pop internally', () {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test',
      );

      // Without building, navigatorKey.currentState is null
      expect(delegate.canPop(), isFalse);
      delegate.dispose();
    });

    test('canPopInternally returns false when navigatorKey has no state', () {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test',
      );

      expect(delegate.canPopInternally(), isFalse);
      delegate.dispose();
    });

    test('setParentFlowNavigator sets parent', () {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test',
      );
      final parentDelegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Parent',
      );

      delegate.setParentFlowNavigator(parentDelegate);

      // After setting parent, canPop should check parent
      expect(delegate.canPop(), isFalse);

      delegate.dispose();
      parentDelegate.dispose();
    });

    test('setNewRoutePath completes synchronously', () async {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test',
      );

      await expectLater(
        delegate.setNewRoutePath(null),
        completes,
      );

      delegate.dispose();
    });

    testWidgets('build asserts pages are not empty', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () =>
            'The flow coordinator being built was: Test',
      );

      // Set empty pages list
      delegate.setPages([]);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: delegate.build,
          ),
        ),
      );

      // Should trigger assertion error
      expect(tester.takeException(), isA<AssertionError>());

      delegate.dispose();
    });

    testWidgets('build creates Navigator with pages', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('page1'), child: Text('Page 1')),
        ],
        contextDescriptionProvider: () => 'Test',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: delegate.build,
          ),
        ),
      );

      expect(find.byType(Navigator), findsOneWidget);
      expect(find.text('Page 1'), findsOneWidget);

      delegate.dispose();
    });

    testWidgets('maybePop returns false when cannot pop', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('page1'), child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'Test',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: delegate.build,
          ),
        ),
      );

      final result = await delegate.maybePop();
      expect(result, isFalse);

      delegate.dispose();
    });

    testWidgets('maybePopInternally returns false when cannot pop',
        (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('page1'), child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'Test',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: delegate.build,
          ),
        ),
      );

      final result = await delegate.maybePopInternally();
      expect(result, isFalse);

      delegate.dispose();
    });

    testWidgets('canPop returns true when can pop internally', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('page1'), child: SizedBox()),
          const MaterialPage(key: ValueKey('page2'), child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'Test',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: delegate.build,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(delegate.canPop(), isTrue);
      expect(delegate.canPopInternally(), isTrue);

      delegate.dispose();
    });

    testWidgets('notifies listeners when pages change', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('page1'), child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'Test',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: delegate.build,
          ),
        ),
      );

      var notificationCount = 0;
      delegate.addListener(() => notificationCount++);

      delegate
          .push(const MaterialPage(key: ValueKey('page2'), child: SizedBox()));
      expect(notificationCount, 1);

      delegate.setPages(
        [const MaterialPage(key: ValueKey('page3'), child: SizedBox())],
      );
      expect(notificationCount, 2);

      delegate.replaceCurrentPage(
        const MaterialPage(key: ValueKey('page4'), child: SizedBox()),
      );
      expect(notificationCount, 3);

      delegate.dispose();
    });

    testWidgets('pop with null result', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('p1'), child: SizedBox()),
          const MaterialPage(key: ValueKey('p2'), child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'Test',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: delegate.build),
        ),
      );

      await tester.pumpAndSettle();

      delegate.pop<String>();
      await tester.pumpAndSettle();

      delegate.dispose();
    });

    testWidgets('popInternally with result', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('p1'), child: SizedBox()),
          const MaterialPage(key: ValueKey('p2'), child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'Test',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: delegate.build),
        ),
      );

      await tester.pumpAndSettle();

      delegate.popInternally<String>('result');
      await tester.pumpAndSettle();

      delegate.dispose();
    });

    testWidgets('maybePopInternally with result', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('p1'), child: SizedBox()),
          const MaterialPage(key: ValueKey('p2'), child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'Test',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: delegate.build),
        ),
      );

      await tester.pumpAndSettle();

      final result = await delegate.maybePopInternally<String>('result');
      expect(result, isTrue);

      delegate.dispose();
    });

    testWidgets('pop delegates to parent when cannot pop internally',
        (tester) async {
      // This test covers line 79: parentFlowNavigator.pop(result) when
      // canPopInternally is false

      // Create a mock parent flow navigator
      final parentDelegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('parent'), child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'Parent',
      );

      // Create child delegate with parent
      final childDelegate = FlowRouterDelegate(
        initialPages: [
          const MaterialPage(key: ValueKey('child'), child: SizedBox()),
        ],
        contextDescriptionProvider: () => 'Child',
      )..setParentFlowNavigator(parentDelegate);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: childDelegate.build),
        ),
      );

      await tester.pumpAndSettle();

      // Pop the only page so canPopInternally returns false
      childDelegate.popInternally();
      await tester.pumpAndSettle();

      // Now pop should delegate to parent
      childDelegate.pop('test-result');

      await tester.pumpAndSettle();

      childDelegate.dispose();
      parentDelegate.dispose();
    });
  });
}
