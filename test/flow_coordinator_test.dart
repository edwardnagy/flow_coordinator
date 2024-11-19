import 'package:flow_coordinator/src/flow_coordinator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'flow_coordinator_test.mocks.dart';

@GenerateMocks([
  RouterDelegate,
  BackButtonDispatcher,
  ChildBackButtonDispatcher,
])
void main() {
  group('FlowCoordinatorState', () {
    late MockRouterDelegate<Object> rootMockRouterDelegate;

    setUp(() {
      rootMockRouterDelegate = MockRouterDelegate<Object>();
      when(rootMockRouterDelegate.currentConfiguration).thenReturn(null);
    });

    group('Back button dispatcher', () {
      testWidgets(
        'Creates a child back button dispatcher from the parent dispatcher and '
        'assigns it to its Router widget',
        (tester) async {
          // Arrange
          // Set up the test coordinator
          final testCoordinatorMockRouterDelegate =
              MockRouterDelegate<TestConfigurationType>();
          when(testCoordinatorMockRouterDelegate.currentConfiguration)
              .thenReturn(null);
          when(testCoordinatorMockRouterDelegate.build(any))
              .thenReturn(Container());
          // Set up the root router delegate
          when(rootMockRouterDelegate.build(any)).thenReturn(
              TestFlowCoordinator(testCoordinatorMockRouterDelegate));
          // Set up the back button dispatcher
          final mockBackButtonDispatcher = MockBackButtonDispatcher();
          final childBackButtonDispatcher = MockChildBackButtonDispatcher();
          when(mockBackButtonDispatcher.createChildBackButtonDispatcher())
              .thenReturn(childBackButtonDispatcher);
          when(childBackButtonDispatcher.parent)
              .thenReturn(mockBackButtonDispatcher);

          // Act
          await tester.pumpWidget(
            WidgetsApp.router(
              color: const Color(0xFF000000),
              routerConfig: RouterConfig(
                routerDelegate: rootMockRouterDelegate,
                backButtonDispatcher: mockBackButtonDispatcher,
              ),
            ),
          );

          // Assert
          final routerWidget = tester.widget<Router<TestConfigurationType>>(
              find.byType(Router<TestConfigurationType>));
          expect(routerWidget.backButtonDispatcher,
              equals(childBackButtonDispatcher));
          verify(mockBackButtonDispatcher.createChildBackButtonDispatcher())
              .called(1);
        },
      );

      testWidgets(
        'Updates the child back button dispatcher when the parent dispatcher changes',
        (tester) async {
          // Arrange
          // Set up the test coordinator
          final testCoordinatorMockRouterDelegate =
              MockRouterDelegate<TestConfigurationType>();
          when(testCoordinatorMockRouterDelegate.currentConfiguration)
              .thenReturn(null);
          when(testCoordinatorMockRouterDelegate.build(any))
              .thenReturn(Container());
          // Set up the root router delegate
          when(rootMockRouterDelegate.build(any)).thenReturn(
              TestFlowCoordinator(testCoordinatorMockRouterDelegate));
          // Set up the back button dispatcher 1
          final mockBackButtonDispatcher1 = MockBackButtonDispatcher();
          final mockchildBackButtonDispatcher1 =
              MockChildBackButtonDispatcher();
          when(mockBackButtonDispatcher1.createChildBackButtonDispatcher())
              .thenReturn(mockchildBackButtonDispatcher1);
          when(mockchildBackButtonDispatcher1.parent)
              .thenReturn(mockBackButtonDispatcher1);
          when(mockBackButtonDispatcher1.forget(mockchildBackButtonDispatcher1))
              .thenReturn(null);
          // Set up the back button dispatcher 2
          final mockBackButtonDispatcher2 = MockBackButtonDispatcher();
          final childBackButtonDispatcher2 = MockChildBackButtonDispatcher();
          when(mockBackButtonDispatcher2.createChildBackButtonDispatcher())
              .thenReturn(childBackButtonDispatcher2);
          when(childBackButtonDispatcher2.parent)
              .thenReturn(mockBackButtonDispatcher2);

          // Act
          await tester.pumpWidget(
            WidgetsApp.router(
              color: const Color(0xFF000000),
              routerConfig: RouterConfig(
                routerDelegate: rootMockRouterDelegate,
                backButtonDispatcher: mockBackButtonDispatcher1,
              ),
            ),
          );

          // Assert
          final routerWidget = tester.widget<Router<TestConfigurationType>>(
              find.byType(Router<TestConfigurationType>));
          expect(routerWidget.backButtonDispatcher,
              equals(mockchildBackButtonDispatcher1));
          verify(mockBackButtonDispatcher1.createChildBackButtonDispatcher())
              .called(1);

          // Act
          await tester.pumpWidget(
            WidgetsApp.router(
              color: const Color(0xFF000000),
              routerConfig: RouterConfig(
                routerDelegate: rootMockRouterDelegate,
                backButtonDispatcher: mockBackButtonDispatcher2,
              ),
            ),
          );

          // Assert
          final routerWidget2 = tester.widget<Router<TestConfigurationType>>(
              find.byType(Router<TestConfigurationType>));
          expect(routerWidget2.backButtonDispatcher,
              equals(childBackButtonDispatcher2));
          verify(mockBackButtonDispatcher1
                  .forget(mockchildBackButtonDispatcher1))
              .called(1);
          verify(mockBackButtonDispatcher2.createChildBackButtonDispatcher())
              .called(1);
        },
      );

      testWidgets(
        'Forgets the child back button dispatcher when the widget is disposed',
        (tester) async {
          // Arrange
          // Set up the test coordinator
          final testCoordinatorMockRouterDelegate =
              MockRouterDelegate<TestConfigurationType>();
          when(testCoordinatorMockRouterDelegate.currentConfiguration)
              .thenReturn(null);
          when(testCoordinatorMockRouterDelegate.build(any))
              .thenReturn(Container());
          // Set up the root router delegate
          when(rootMockRouterDelegate.build(any)).thenReturn(
              TestFlowCoordinator(testCoordinatorMockRouterDelegate));
          // Set up the back button dispatcher
          final mockBackButtonDispatcher = MockBackButtonDispatcher();
          final childBackButtonDispatcher = MockChildBackButtonDispatcher();
          when(mockBackButtonDispatcher.createChildBackButtonDispatcher())
              .thenReturn(childBackButtonDispatcher);
          when(childBackButtonDispatcher.parent)
              .thenReturn(mockBackButtonDispatcher);
          when(mockBackButtonDispatcher.forget(childBackButtonDispatcher))
              .thenReturn(null);

          // Act
          await tester.pumpWidget(
            WidgetsApp.router(
              color: const Color(0xFF000000),
              routerConfig: RouterConfig(
                routerDelegate: rootMockRouterDelegate,
                backButtonDispatcher: mockBackButtonDispatcher,
              ),
            ),
          );

          // Assert
          final routerWidget = tester.widget<Router<TestConfigurationType>>(
              find.byType(Router<TestConfigurationType>));
          expect(routerWidget.backButtonDispatcher,
              equals(childBackButtonDispatcher));
          verifyNever(
              mockBackButtonDispatcher.forget(childBackButtonDispatcher));

          // Act
          await tester.pumpWidget(
            const SizedBox(),
          );

          // Assert
          verify(mockBackButtonDispatcher.forget(childBackButtonDispatcher))
              .called(1);
        },
      );

      testWidgets(
        'Takes priority when the widget is built',
        (tester) async {
          // Arrange
          // Set up the test coordinator
          final testCoordinatorMockRouterDelegate =
              MockRouterDelegate<TestConfigurationType>();
          when(testCoordinatorMockRouterDelegate.currentConfiguration)
              .thenReturn(null);
          when(testCoordinatorMockRouterDelegate.build(any))
              .thenReturn(Container());
          // Set up the root router delegate
          when(rootMockRouterDelegate.build(any)).thenReturn(
              TestFlowCoordinator(testCoordinatorMockRouterDelegate));
          // Set up the back button dispatcher
          final mockBackButtonDispatcher = MockBackButtonDispatcher();
          final mockChildBackButtonDispatcher = MockChildBackButtonDispatcher();
          when(mockBackButtonDispatcher.createChildBackButtonDispatcher())
              .thenReturn(mockChildBackButtonDispatcher);
          when(mockChildBackButtonDispatcher.parent)
              .thenReturn(mockBackButtonDispatcher);
          when(mockChildBackButtonDispatcher.takePriority()).thenReturn(null);

          // Act
          await tester.pumpWidget(
            WidgetsApp.router(
              color: const Color(0xFF000000),
              routerConfig: RouterConfig(
                routerDelegate: rootMockRouterDelegate,
                backButtonDispatcher: mockBackButtonDispatcher,
              ),
            ),
          );

          // Assert
          verify(mockChildBackButtonDispatcher.takePriority()).called(1);
        },
      );
    });
  });
}

class TestConfigurationType {}

class TestFlowCoordinator<T> extends FlowCoordinator {
  const TestFlowCoordinator(this.routerDelegate, {super.key});

  final RouterDelegate<T> routerDelegate;

  @override
  FlowCoordinatorState createState() => _TestFlowCoordinatorState<T>();
}

final class _TestFlowCoordinatorState<T>
    extends FlowCoordinatorState<TestFlowCoordinator<T>, T> {
  _TestFlowCoordinatorState();

  @override
  RouterDelegate<T> get routerDelegate => widget.routerDelegate;
}
