import 'package:flow_coordinator/src/flow_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock or concrete implementation for testing
class TestFlowNavigator implements FlowNavigator {
  @override
  bool canPop() => true;

  @override
  bool canPopInternally() => true;

  @override
  void pop<T extends Object?>([T? result]) {}

  @override
  void popInternally<T extends Object?>([T? result]) {}

  @override
  void push(Page page) {}

  @override
  void setPages(List<Page> pages) {}

  @override
  void replaceCurrentPage(Page page) {}

  @override
  Future<bool> maybePop<T extends Object?>([T? result]) async => false;

  @override
  Future<bool> maybePopInternally<T extends Object?>([T? result]) async =>
      false;
}

void main() {
  group('FlowNavigator', () {
    testWidgets('maybeOf returns null when not found', (tester) async {
      await tester.pumpWidget(Container());
      final context = tester.element(find.byType(Container));
      
      // Test both with and without listen parameter
      expect(FlowNavigator.maybeOf(context), isNull);
      expect(FlowNavigator.maybeOf(context, listen: true), isNull);
    });

    testWidgets('of throws when not found', (tester) async {
      await tester.pumpWidget(Container());
      final context = tester.element(find.byType(Container));
      expect(() => FlowNavigator.of(context), throwsA(isA<FlutterError>()));
    });

    testWidgets('finds FlowNavigator when provided', (tester) async {
      final navigator = TestFlowNavigator();
      await tester.pumpWidget(
        FlowNavigatorScope(
          flowNavigator: navigator,
          child: Builder(
            builder: (context) {
              return Container();
            },
          ),
        ),
      );
      final context = tester.element(find.byType(Container));
      
      // Test both with and without listen parameter
      expect(FlowNavigator.of(context), navigator);
      expect(FlowNavigator.of(context, listen: true), navigator);
    });

    test(
        'FlowNavigatorScope updateShouldNotify returns true when '
        'navigator changes', () {
      final nav1 = TestFlowNavigator();
      final nav2 = TestFlowNavigator();
      final scope1 =
          FlowNavigatorScope(flowNavigator: nav1, child: Container());
      final scope2 =
          FlowNavigatorScope(flowNavigator: nav2, child: Container());
      expect(scope2.updateShouldNotify(scope1), true);
    });

    test(
        'FlowNavigatorScope updateShouldNotify returns false when '
        'navigator same', () {
      final nav = TestFlowNavigator();
      final scope1 = FlowNavigatorScope(flowNavigator: nav, child: Container());
      final scope2 = FlowNavigatorScope(flowNavigator: nav, child: Container());
      expect(scope2.updateShouldNotify(scope1), false);
    });
  });
}
