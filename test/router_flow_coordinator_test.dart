import 'package:flow_coordinator/src/router_flow_coordinator_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'router_flow_coordinator_test.mocks.dart';

@GenerateMocks([
  RouterDelegate,
  BackButtonDispatcher,
  ChildBackButtonDispatcher,
])
void main() {
  late MockRouterDelegate<Object> mockRootRouterDelegate;

  setUp(() {
    mockRootRouterDelegate = MockRouterDelegate<Object>();
    when(mockRootRouterDelegate.currentConfiguration).thenReturn(null);
  });

  testWidgets(
    'Default back button dispatcher is created and updated without a provided dispatcher',
    (tester) async {
      // Set up the test flow coordinator
      final testCoordinatorMockRouterDelegate =
          MockRouterDelegate<TestConfigurationType>();
      when(testCoordinatorMockRouterDelegate.currentConfiguration)
          .thenReturn(null);
      when(testCoordinatorMockRouterDelegate.build(any))
          .thenReturn(Container());
      final testFlowCoordinator = TestRouterFlowCoordinator(
        routerConfig: RouterConfig(
          routerDelegate: testCoordinatorMockRouterDelegate,
        ),
      );
      when(mockRootRouterDelegate.build(any)).thenReturn(testFlowCoordinator);
      // Set up the back button dispatcher 1
      final mockRootDispatcher1 = MockBackButtonDispatcher();
      final mockChildDispatcher1 = MockChildBackButtonDispatcher();
      when(mockRootDispatcher1.createChildBackButtonDispatcher())
          .thenReturn(mockChildDispatcher1);
      when(mockChildDispatcher1.parent).thenReturn(mockRootDispatcher1);
      when(mockRootDispatcher1.forget(mockChildDispatcher1)).thenReturn(null);
      // Set up the back button dispatcher 2
      final mockRootDispatcher2 = MockBackButtonDispatcher();
      final mockChildDispatcher2 = MockChildBackButtonDispatcher();
      when(mockRootDispatcher2.createChildBackButtonDispatcher())
          .thenReturn(mockChildDispatcher2);
      when(mockChildDispatcher2.parent).thenReturn(mockRootDispatcher2);

      // Build the widget with the first back button dispatcher
      await tester.pumpWidget(
        WidgetsApp.router(
          color: const Color(0xFF000000),
          routerConfig: RouterConfig(
            routerDelegate: mockRootRouterDelegate,
            backButtonDispatcher: mockRootDispatcher1,
          ),
        ),
      );

      final routerWidget = tester.widget<Router<TestConfigurationType>>(
          find.byType(Router<TestConfigurationType>));
      expect(routerWidget.backButtonDispatcher, equals(mockChildDispatcher1));
      verify(mockRootDispatcher1.createChildBackButtonDispatcher()).called(1);

      // Build the widget with the second back button dispatcher
      await tester.pumpWidget(
        WidgetsApp.router(
          color: const Color(0xFF000000),
          routerConfig: RouterConfig(
            routerDelegate: mockRootRouterDelegate,
            backButtonDispatcher: mockRootDispatcher2,
          ),
        ),
      );

      final routerWidget2 = tester.widget<Router<TestConfigurationType>>(
          find.byType(Router<TestConfigurationType>));
      expect(routerWidget2.backButtonDispatcher, equals(mockChildDispatcher2));
      verify(mockRootDispatcher1.forget(mockChildDispatcher1)).called(1);
      verify(mockRootDispatcher2.createChildBackButtonDispatcher()).called(1);
    },
  );

  testWidgets(
    'Default back button dispatcher is forgotten on widget disposal',
    (tester) async {
      // Set up the test coordinator
      final testCoordinatorMockRouterDelegate =
          MockRouterDelegate<TestConfigurationType>();
      when(testCoordinatorMockRouterDelegate.currentConfiguration)
          .thenReturn(null);
      when(testCoordinatorMockRouterDelegate.build(any))
          .thenReturn(Container());
      when(mockRootRouterDelegate.build(any)).thenReturn(
        TestRouterFlowCoordinator(
          routerConfig: RouterConfig(
            routerDelegate: testCoordinatorMockRouterDelegate,
          ),
        ),
      );
      // Set up the back button dispatcher
      final mockRootDispatcher = MockBackButtonDispatcher();
      final mockChildDispatcher = MockChildBackButtonDispatcher();
      when(mockRootDispatcher.createChildBackButtonDispatcher())
          .thenReturn(mockChildDispatcher);
      when(mockChildDispatcher.parent).thenReturn(mockRootDispatcher);
      when(mockRootDispatcher.forget(mockChildDispatcher)).thenReturn(null);

      await tester.pumpWidget(
        WidgetsApp.router(
          color: const Color(0xFF000000),
          routerConfig: RouterConfig(
            routerDelegate: mockRootRouterDelegate,
            backButtonDispatcher: mockRootDispatcher,
          ),
        ),
      );

      final routerWidget = tester.widget<Router<TestConfigurationType>>(
          find.byType(Router<TestConfigurationType>));
      expect(routerWidget.backButtonDispatcher, equals(mockChildDispatcher));
      verifyNever(mockRootDispatcher.forget(mockChildDispatcher));

      await tester.pumpWidget(
        const SizedBox(),
      );

      verify(mockRootDispatcher.forget(mockChildDispatcher)).called(1);
    },
  );

  testWidgets(
    'Default back button dispatcher takes priority upon widget build',
    (tester) async {
      // Set up the test coordinator
      final testCoordinatorMockRouterDelegate =
          MockRouterDelegate<TestConfigurationType>();
      when(testCoordinatorMockRouterDelegate.currentConfiguration)
          .thenReturn(null);
      when(testCoordinatorMockRouterDelegate.build(any))
          .thenReturn(Container());
      when(mockRootRouterDelegate.build(any)).thenReturn(
        TestRouterFlowCoordinator(
          routerConfig: RouterConfig(
            routerDelegate: testCoordinatorMockRouterDelegate,
          ),
        ),
      );
      // Set up the back button dispatcher
      final mockRootDispatcher = MockBackButtonDispatcher();
      final mockChildDispatcher = MockChildBackButtonDispatcher();
      when(mockRootDispatcher.createChildBackButtonDispatcher())
          .thenReturn(mockChildDispatcher);
      when(mockChildDispatcher.parent).thenReturn(mockRootDispatcher);
      when(mockChildDispatcher.takePriority()).thenReturn(null);

      var counter = 0;
      Color getColor() => Color(0xFF000000 + counter++);

      await tester.pumpWidget(
        WidgetsApp.router(
          color: getColor(),
          routerConfig: RouterConfig(
            routerDelegate: mockRootRouterDelegate,
            backButtonDispatcher: mockRootDispatcher,
          ),
        ),
      );

      verify(mockChildDispatcher.takePriority()).called(1);
    },
  );

  testWidgets(
    'Provided back button dispatcher is used when specified',
    (tester) async {
      // Set up the test coordinator
      final testCoordinatorMockRouterDelegate =
          MockRouterDelegate<TestConfigurationType>();
      when(testCoordinatorMockRouterDelegate.currentConfiguration)
          .thenReturn(null);
      when(testCoordinatorMockRouterDelegate.build(any))
          .thenReturn(Container());
      final mockDispatcher = MockBackButtonDispatcher();
      when(mockRootRouterDelegate.build(any)).thenReturn(
        TestRouterFlowCoordinator(
          routerConfig: RouterConfig(
            routerDelegate: testCoordinatorMockRouterDelegate,
            backButtonDispatcher: mockDispatcher,
          ),
        ),
      );

      await tester.pumpWidget(
        WidgetsApp.router(
          color: const Color(0xFF000000),
          routerConfig: RouterConfig(
            routerDelegate: mockRootRouterDelegate,
          ),
        ),
      );

      final routerWidget = tester.widget<Router<TestConfigurationType>>(
          find.byType(Router<TestConfigurationType>));
      expect(routerWidget.backButtonDispatcher, equals(mockDispatcher));
    },
  );

  testWidgets(
    'Default back button dispatcher is replaced and forgotten with the provided dispatcher',
    (tester) async {
      // Set up the test coordinator
      final testCoordinatorMockRouterDelegate =
          MockRouterDelegate<TestConfigurationType>();
      when(testCoordinatorMockRouterDelegate.currentConfiguration)
          .thenReturn(null);
      when(testCoordinatorMockRouterDelegate.build(any))
          .thenReturn(Container());
      // Set up the root back button dispatcher
      final rootDispatcher = MockBackButtonDispatcher();
      final childDispatcher = MockChildBackButtonDispatcher();
      when(rootDispatcher.createChildBackButtonDispatcher())
          .thenReturn(childDispatcher);
      when(childDispatcher.parent).thenReturn(rootDispatcher);
      when(rootDispatcher.forget(childDispatcher)).thenReturn(null);
      // Set up listener for root router delegate
      late final VoidCallback rootRouterListener;
      when(mockRootRouterDelegate.addListener(captureAny))
          .thenAnswer((invocation) {
        rootRouterListener = invocation.positionalArguments[0] as VoidCallback;
      });

      // Do not provide a back button dispatcher, so the default one is created
      when(mockRootRouterDelegate.build(any)).thenReturn(
        TestRouterFlowCoordinator(
          routerConfig: RouterConfig(
            routerDelegate: testCoordinatorMockRouterDelegate,
          ),
        ),
      );

      await tester.pumpWidget(
        WidgetsApp.router(
          color: const Color(0xFF000000),
          routerConfig: RouterConfig(
            routerDelegate: mockRootRouterDelegate,
            backButtonDispatcher: rootDispatcher,
          ),
        ),
      );

      final initialRouterWidget = tester.widget<Router<TestConfigurationType>>(
          find.byType(Router<TestConfigurationType>));
      expect(initialRouterWidget.backButtonDispatcher, equals(childDispatcher));
      verifyNever(rootDispatcher.forget(childDispatcher));

      // Provide a new back button dispatcher
      final mockDispatcher = MockBackButtonDispatcher();
      when(mockRootRouterDelegate.build(any)).thenReturn(
        TestRouterFlowCoordinator(
          routerConfig: RouterConfig(
            routerDelegate: testCoordinatorMockRouterDelegate,
            backButtonDispatcher: mockDispatcher,
          ),
        ),
      );
      rootRouterListener();
      await tester.pump();

      final updatedRouterWidget = tester.widget<Router<TestConfigurationType>>(
          find.byType(Router<TestConfigurationType>));
      verify(rootDispatcher.forget(childDispatcher)).called(1);
      expect(updatedRouterWidget.backButtonDispatcher, equals(mockDispatcher));
    },
  );
}

class TestConfigurationType {}

class TestRouterFlowCoordinator<T> extends StatefulWidget {
  const TestRouterFlowCoordinator({super.key, required this.routerConfig});

  final RouterConfig<T> routerConfig;

  @override
  State<TestRouterFlowCoordinator> createState() =>
      _TestRouterFlowCoordinatorState<T>();
}

class _TestRouterFlowCoordinatorState<T>
    extends RouterFlowCoordinatorState<TestRouterFlowCoordinator<T>, T> {
  @override
  RouterConfig<T> get routerConfig => widget.routerConfig;
}
