import 'package:flow_coordinator/src/flow_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowNavigator', () {
    group('of', () {
      testWidgets(
        'throws FlutterError when no scope exists',
        (tester) async {
          FlutterError? caughtError;
          await tester.pumpWidget(
            Builder(
              builder: (context) {
                try {
                  FlowNavigator.of(context);
                } on FlutterError catch (e) {
                  caughtError = e;
                }
                return const SizedBox();
              },
            ),
          );

          expect(caughtError, isNotNull);
          expect(
            caughtError.toString(),
            contains('FlowNavigator.of() called with a context'),
          );
        },
      );

      group('listen behavior', () {
        late int childBuildCount;
        late _MockFlowNavigator navigator1;
        late _MockFlowNavigator navigator2;
        late _MockFlowNavigator currentNavigator;

        setUp(() {
          childBuildCount = 0;
          navigator1 = _MockFlowNavigator();
          navigator2 = _MockFlowNavigator();
          currentNavigator = navigator1;
        });

        testWidgets(
          'listen: true triggers rebuild when navigator changes',
          (tester) async {
            late StateSetter setOuterState;

            final child = Builder(
              builder: (context) {
                FlowNavigator.of(context, listen: true);
                childBuildCount++;
                return const SizedBox();
              },
            );

            await tester.pumpWidget(
              StatefulBuilder(
                builder: (context, setState) {
                  setOuterState = setState;
                  return FlowNavigatorScope(
                    flowNavigator: currentNavigator,
                    child: child,
                  );
                },
              ),
            );

            expect(childBuildCount, 1);

            setOuterState(() => currentNavigator = navigator2);
            await tester.pump();

            expect(childBuildCount, 2);
          },
        );

        testWidgets(
          'listen: false does not trigger rebuild when navigator changes',
          (tester) async {
            late StateSetter setOuterState;

            final child = Builder(
              builder: (context) {
                FlowNavigator.of(context, listen: false);
                childBuildCount++;
                return const SizedBox();
              },
            );

            await tester.pumpWidget(
              StatefulBuilder(
                builder: (context, setState) {
                  setOuterState = setState;
                  return FlowNavigatorScope(
                    flowNavigator: currentNavigator,
                    child: child,
                  );
                },
              ),
            );

            expect(childBuildCount, 1);

            setOuterState(() => currentNavigator = navigator2);
            await tester.pump();

            expect(childBuildCount, 1);
          },
        );
      });
    });

    group('maybeOf', () {
      testWidgets(
        'returns null when no scope exists',
        (tester) async {
          FlowNavigator? navigator;
          await tester.pumpWidget(
            Builder(
              builder: (context) {
                navigator = FlowNavigator.maybeOf(context);
                return const SizedBox();
              },
            ),
          );

          expect(navigator, isNull);
        },
      );

      group('listen behavior', () {
        late int childBuildCount;
        late _MockFlowNavigator navigator1;
        late _MockFlowNavigator navigator2;
        late _MockFlowNavigator currentNavigator;

        setUp(() {
          childBuildCount = 0;
          navigator1 = _MockFlowNavigator();
          navigator2 = _MockFlowNavigator();
          currentNavigator = navigator1;
        });

        testWidgets(
          'listen: true triggers rebuild when navigator changes',
          (tester) async {
            late StateSetter setOuterState;

            final child = Builder(
              builder: (context) {
                FlowNavigator.maybeOf(context, listen: true);
                childBuildCount++;
                return const SizedBox();
              },
            );

            await tester.pumpWidget(
              StatefulBuilder(
                builder: (context, setState) {
                  setOuterState = setState;
                  return FlowNavigatorScope(
                    flowNavigator: currentNavigator,
                    child: child,
                  );
                },
              ),
            );

            expect(childBuildCount, 1);

            setOuterState(() => currentNavigator = navigator2);
            await tester.pump();

            expect(childBuildCount, 2);
          },
        );

        testWidgets(
          'listen: false does not trigger rebuild when navigator changes',
          (tester) async {
            late StateSetter setOuterState;

            final child = Builder(
              builder: (context) {
                FlowNavigator.maybeOf(context, listen: false);
                childBuildCount++;
                return const SizedBox();
              },
            );

            await tester.pumpWidget(
              StatefulBuilder(
                builder: (context, setState) {
                  setOuterState = setState;
                  return FlowNavigatorScope(
                    flowNavigator: currentNavigator,
                    child: child,
                  );
                },
              ),
            );

            expect(childBuildCount, 1);

            setOuterState(() => currentNavigator = navigator2);
            await tester.pump();

            expect(childBuildCount, 1);
          },
        );
      });
    });
  });
}

class _MockFlowNavigator implements FlowNavigator {
  @override
  void push(Page page) {}

  @override
  void setPages(List<Page> pages) {}

  @override
  void replaceCurrentPage(Page page) {}

  @override
  bool canPop() => false;

  @override
  bool canPopInternally() => false;

  @override
  Future<bool> maybePop<T extends Object?>([T? result]) => Future.value(false);

  @override
  Future<bool> maybePopInternally<T extends Object?>([T? result]) =>
      Future.value(false);

  @override
  void pop<T extends Object?>([T? result]) {}

  @override
  void popInternally<T extends Object?>([T? result]) {}
}
