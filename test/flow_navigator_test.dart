import 'package:flow_coordinator/src/flow_navigator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowNavigator', () {
    testWidgets('maybeOf returns null when no FlowNavigator found',
        (tester) async {
      await tester.pumpWidget(const SizedBox());

      final context = tester.element(find.byType(SizedBox));
      expect(FlowNavigator.maybeOf(context), isNull);
    });

    testWidgets('maybeOf returns FlowNavigator when found', (tester) async {
      final navigator = _MockFlowNavigator();
      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: navigator,
          child: const SizedBox(),
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      expect(FlowNavigator.maybeOf(context), navigator);
    });

    testWidgets('of returns FlowNavigator when found', (tester) async {
      final navigator = _MockFlowNavigator();
      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: navigator,
          child: const SizedBox(),
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      expect(FlowNavigator.of(context), navigator);
    });

    testWidgets('of throws FlutterError when no FlowNavigator found',
        (tester) async {
      await tester.pumpWidget(const SizedBox());

      final context = tester.element(find.byType(SizedBox));
      expect(() => FlowNavigator.of(context), throwsA(isA<FlutterError>()));
    });
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
