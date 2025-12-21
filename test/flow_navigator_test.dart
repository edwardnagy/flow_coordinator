import 'package:flow_coordinator/src/flow_navigator.dart';
import 'package:flow_coordinator/src/flow_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowNavigator.of', () {
    testWidgets('finds FlowNavigator in widget tree without listening',
        (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test',
      );
      FlowNavigator? found;

      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: delegate,
          child: Builder(
            builder: (context) {
              found = FlowNavigator.of(context, listen: false);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(found, same(delegate));
      delegate.dispose();
    });

    testWidgets('finds FlowNavigator in widget tree with listening',
        (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test',
      );
      FlowNavigator? found;

      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: delegate,
          child: Builder(
            builder: (context) {
              found = FlowNavigator.of(context, listen: true);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(found, same(delegate));
      delegate.dispose();
    });

    testWidgets('throws FlutterError when no FlowNavigatorScope found',
        (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => FlowNavigator.of(context),
              throwsA(isA<FlutterError>()),
            );
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('error message includes context information', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              FlowNavigator.of(context);
              fail('Should have thrown FlutterError');
            } catch (e) {
              expect(e, isA<FlutterError>());
              expect(
                e.toString(),
                contains('FlowNavigator.of() called with a context'),
              );
            }
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('FlowNavigator.maybeOf', () {
    testWidgets('returns FlowNavigator when found without listening',
        (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test',
      );
      FlowNavigator? found;

      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: delegate,
          child: Builder(
            builder: (context) {
              found = FlowNavigator.maybeOf(context, listen: false);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(found, same(delegate));
      delegate.dispose();
    });

    testWidgets('returns FlowNavigator when found with listening',
        (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test',
      );
      FlowNavigator? found;

      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: delegate,
          child: Builder(
            builder: (context) {
              found = FlowNavigator.maybeOf(context, listen: true);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(found, same(delegate));
      delegate.dispose();
    });

    testWidgets('returns null when no FlowNavigatorScope found',
        (tester) async {
      FlowNavigator? found;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            found = FlowNavigator.maybeOf(context);
            return const SizedBox();
          },
        ),
      );

      expect(found, isNull);
    });
  });

  group('FlowNavigatorScope', () {
    testWidgets('provides flowNavigator to descendants', (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test',
      );

      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: delegate,
          child: Builder(
            builder: (context) {
              final found = FlowNavigator.maybeOf(context);
              expect(found, same(delegate));
              return const SizedBox();
            },
          ),
        ),
      );

      delegate.dispose();
    });

    testWidgets('updateShouldNotify returns true when flowNavigator changes',
        (tester) async {
      final delegate1 = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test1',
      );
      final delegate2 = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test2',
      );
      var rebuildCount = 0;

      var builder = Builder(
        builder: (context) {
          FlowNavigator.of(context, listen: true);
          rebuildCount++;
          return const SizedBox();
        },
      );

      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: delegate1,
          child: builder,
        ),
      );

      expect(rebuildCount, 1);

      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: delegate2,
          child: builder,
        ),
      );

      expect(rebuildCount, 2);

      delegate1.dispose();
      delegate2.dispose();
    });

    testWidgets('updateShouldNotify returns false when same flowNavigator',
        (tester) async {
      final delegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Test',
      );
      var rebuildCount = 0;

      var builder = Builder(
        builder: (context) {
          FlowNavigator.maybeOf(context);
          rebuildCount++;
          return const SizedBox();
        },
      );

      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: delegate,
          child: builder,
        ),
      );

      expect(rebuildCount, 1);

      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: delegate,
          child: builder,
        ),
      );

      // Should not rebuild since delegate is the same
      expect(rebuildCount, 1);

      delegate.dispose();
    });

    testWidgets('nested scopes return nearest scope', (tester) async {
      final outerDelegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Outer',
      );
      final innerDelegate = FlowRouterDelegate(
        initialPages: [const MaterialPage(child: SizedBox())],
        contextDescriptionProvider: () => 'Inner',
      );
      FlowNavigator? outerFound;
      FlowNavigator? innerFound;

      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: outerDelegate,
          child: Builder(
            builder: (context) {
              outerFound = FlowNavigator.maybeOf(context);
              return FlowNavigatorScope(
                flowNavigator: innerDelegate,
                child: Builder(
                  builder: (context) {
                    innerFound = FlowNavigator.maybeOf(context);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(outerFound, same(outerDelegate));
      expect(innerFound, same(innerDelegate));
      expect(innerFound, isNot(same(outerFound)));

      outerDelegate.dispose();
      innerDelegate.dispose();
    });
  });
}
