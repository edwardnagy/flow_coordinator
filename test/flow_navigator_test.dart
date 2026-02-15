import 'package:flow_coordinator/src/flow_navigator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  group('FlowNavigator', () {
    testWidgets(
      'of returns navigator when scope is present',
      (tester) async {
        final navigator = _MockFlowNavigator();
        late FlowNavigator result;
        await tester.pumpWidget(
          FlowNavigatorScope(
            flowNavigator: navigator,
            child: Builder(
              builder: (context) {
                result = FlowNavigator.of(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(result, navigator);
      },
    );

    testWidgets(
      'of with listen=true uses dependOnInheritedWidgetOfExactType',
      (tester) async {
        final navigator = _MockFlowNavigator();
        late FlowNavigator result;
        await tester.pumpWidget(
          FlowNavigatorScope(
            flowNavigator: navigator,
            child: Builder(
              builder: (context) {
                result = FlowNavigator.of(context, listen: true);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(result, navigator);
      },
    );

    testWidgets('of throws when scope is not present', (tester) async {
      late FlutterError error;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              FlowNavigator.of(context);
            } on FlutterError catch (e) {
              error = e;
            }
            return const SizedBox();
          },
        ),
      );
      expect(
        error.toString(),
        contains('FlowNavigatorScope'),
      );
    });

    testWidgets(
      'maybeOf returns navigator when scope is present',
      (tester) async {
        final navigator = _MockFlowNavigator();
        FlowNavigator? result;
        await tester.pumpWidget(
          FlowNavigatorScope(
            flowNavigator: navigator,
            child: Builder(
              builder: (context) {
                result = FlowNavigator.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(result, navigator);
      },
    );

    testWidgets(
      'maybeOf with listen=true returns navigator when scope is present',
      (tester) async {
        final navigator = _MockFlowNavigator();
        FlowNavigator? result;
        await tester.pumpWidget(
          FlowNavigatorScope(
            flowNavigator: navigator,
            child: Builder(
              builder: (context) {
                result = FlowNavigator.maybeOf(context, listen: true);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(result, navigator);
      },
    );

    testWidgets(
      'maybeOf returns null when scope is not present',
      (tester) async {
        FlowNavigator? result;
        await tester.pumpWidget(
          Builder(
            builder: (context) {
              result = FlowNavigator.maybeOf(context);
              return const SizedBox();
            },
          ),
        );
        expect(result, isNull);
      },
    );
  });

  group('FlowNavigatorScope', () {
    test(
      'updateShouldNotify returns true when navigator differs',
      () {
        final navigator1 = _MockFlowNavigator();
        final navigator2 = _MockFlowNavigator();
        final scope = FlowNavigatorScope(
          flowNavigator: navigator1,
          child: const SizedBox(),
        );
        expect(
          scope.updateShouldNotify(
            FlowNavigatorScope(
              flowNavigator: navigator2,
              child: const SizedBox(),
            ),
          ),
          isTrue,
        );
      },
    );

    test(
      'updateShouldNotify returns false when navigator is same',
      () {
        final navigator = _MockFlowNavigator();
        final scope = FlowNavigatorScope(
          flowNavigator: navigator,
          child: const SizedBox(),
        );
        expect(
          scope.updateShouldNotify(
            FlowNavigatorScope(
              flowNavigator: navigator,
              child: const SizedBox(),
            ),
          ),
          isFalse,
        );
      },
    );
  });
}
