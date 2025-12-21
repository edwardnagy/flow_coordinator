# Flow Coordinator Tests

This directory contains comprehensive tests for the flow_coordinator package, aiming for 100% code coverage.

## Running Tests

To run all tests:

```bash
flutter test
```

To run tests with coverage:

```bash
flutter test --coverage
```

To view coverage report:

```bash
# Install lcov if not already installed
# On Ubuntu/Debian: sudo apt-get install lcov
# On macOS: brew install lcov

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open the report in a browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

## Test Structure

The tests are organized to mirror the source code structure:

- `consumable_test.dart` - Tests for the Consumable value wrapper
- `identity_route_information_parser_test.dart` - Tests for the identity parser
- `flow_route_status_scope_test.dart` - Tests for route status inherited widget
- `route_information_combiner_test.dart` - Tests for URI combining logic
- `flow_coordinator_test.dart` - Tests for FlowCoordinator context lookup
- `flow_navigator_test.dart` - Tests for FlowNavigator interface and scope
- `flow_route_scope_test.dart` - Tests for FlowRouteScope and URL matching
- `flow_route_information_provider_test.dart` - Tests for route information providers
- `route_information_reporter_delegate_test.dart` - Tests for reporting delegates
- `flow_router_delegate_test.dart` - Tests for router delegate implementation
- `route_information_reporter_test.dart` - Tests for route information reporter widget
- `child_route_information_filter_test.dart` - Tests for route filtering
- `flow_back_button_dispatcher_builder_test.dart` - Tests for back button handling
- `flow_coordinator_mixin_test.dart` - Tests for the main FlowCoordinatorMixin
- `flow_coordinator_router_test.dart` - Tests for FlowCoordinatorRouter configuration
- `integration_test.dart` - End-to-end integration tests

Each test file includes edge case tests integrated with the main test suites.

## Coverage Goals

The test suite aims to achieve:
- **100% line coverage** - Every line of code is executed
- **100% branch coverage** - All conditional branches are tested
- **100% function coverage** - All functions are invoked

## Test Categories

### Unit Tests
Most test files contain unit tests that test individual classes and functions in isolation.

### Widget Tests
Tests that use Flutter's widget testing framework to test widgets and their interactions:
- `flow_route_status_scope_test.dart`
- `route_information_combiner_test.dart`
- `flow_navigator_test.dart`
- `flow_route_scope_test.dart`
- `route_information_reporter_test.dart`
- `child_route_information_filter_test.dart`
- `flow_back_button_dispatcher_builder_test.dart`
- `flow_coordinator_mixin_test.dart`
- `flow_coordinator_router_test.dart`

### Integration Tests
`integration_test.dart` contains end-to-end tests that exercise the complete flow coordinator stack.

### Edge Cases
Edge case tests are integrated into each component's test file, covering:
- Null and empty values
- Special characters and complex data structures
- Boundary conditions
- Rapid updates and concurrent operations

## Testing Approach

1. **Positive Cases**: Tests verify that functionality works as expected with valid inputs
2. **Negative Cases**: Tests verify proper error handling with invalid inputs
3. **Edge Cases**: Tests cover boundary conditions and special cases (integrated in each test file)
4. **State Management**: Tests verify that state changes propagate correctly
5. **Lifecycle**: Tests verify proper initialization and disposal
6. **Integration**: Tests verify that components work together correctly

## Common Test Patterns

### Testing InheritedWidgets
```dart
testWidgets('provides value to descendants', (tester) async {
  await tester.pumpWidget(
    MyInheritedWidget(
      value: testValue,
      child: Builder(
        builder: (context) {
          final found = MyInheritedWidget.of(context);
          expect(found, equals(testValue));
          return const SizedBox();
        },
      ),
    ),
  );
});
```

### Testing Stateful Widgets
```dart
testWidgets('updates when state changes', (tester) async {
  await tester.pumpWidget(MyStatefulWidget());
  
  // Initial state
  expect(find.text('Initial'), findsOneWidget);
  
  // Trigger state change
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  
  // Verify new state
  expect(find.text('Updated'), findsOneWidget);
});
```

### Testing Async Operations
```dart
testWidgets('handles async operations', (tester) async {
  await tester.pumpWidget(MyWidget());
  
  await tester.tap(find.byType(ElevatedButton));
  
  // Wait for async operations to complete
  await tester.pumpAndSettle();
  
  expect(find.text('Loaded'), findsOneWidget);
});
```

## Continuous Integration

These tests are designed to run in CI environments. Ensure your CI configuration includes:

```yaml
- name: Run Tests
  run: flutter test --coverage

- name: Check Coverage
  run: |
    flutter test --coverage
    # Optionally: Upload to coverage service like Codecov
```

## Contributing

When adding new features to the package:
1. Write tests first (TDD approach recommended)
2. Ensure all tests pass: `flutter test`
3. Verify coverage remains at 100%: `flutter test --coverage`
4. Add integration tests for new user-facing features
