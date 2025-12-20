A navigation and routing API that organizes screens into *user flows*, using the
Flow Controller (Coordinator) pattern.

![Flow Coordinator Illustration](https://github.com/user-attachments/assets/b356c195-48a8-4f36-9415-8d9344f5324d)

## Features

Use Flow Coordinators to:

- Reuse screens and flows across different parts of your app.
- Separate complex navigation logic from UI code.
- Handle deep linking and complex routing scenarios modularly.
- Update the browser URL to reflect the current route.
- Restore the app state after termination.
- Guard screens from unauthorized access — for example, redirect to login if the
user is not authenticated.
- Support nested routing with tabs.
- Preserve compatibility with the Navigator API.

## Getting Started

To configure your app, set the `routerConfig` parameter of `MaterialApp.router`
or `CupertinoApp.router` to a `FlowCoordinatorRouter`, and provide a builder for
the root Flow Coordinator of your app:

```dart
import 'package:flow_coordinator/flow_coordinator.dart';

final _router = FlowCoordinatorRouter(
    homeBuilder: (context) => const MyFlowCoordinator(),
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}
```

## Usage

This section has code examples for the following navigation scenarios:

- [Navigating Between Screens](#navigating-between-screens)
- [Deep Link Handling](#deep-link-handling)
- [Updating the Browser URL](#updating-the-browser-url)
- [Tabbed Navigation with Nested Routing](#tabbed-navigation-with-nested-routing)

A complete example app that meets all navigation requirements identified by the
Flutter team in their [Routing API Usability Research](https://github.com/flutter/uxr/blob/master/docs/Flutter-Routing-API-Usability-Research.md)
as “important yet difficult to implement” is available in the [example](example/)
directory.

### Navigating Between Screens

Create an interface for your screen's navigation events. The interface should implement
`FlowCoordinatorMixin`:

```dart
abstract interface class MyScreenListener<T extends StatefulWidget>
    implements FlowCoordinatorMixin<T> {
  void onButtonPressed();
}
```

In your screen widget, use `FlowCoordinatorMixin.of<MyScreenListener>(context)`
to retrieve the nearest Flow Coordinator that implements the listener interface.
Call the appropriate method when a navigation event occurs:

```dart
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final listener = FlowCoordinatorMixin.of<MyScreenListener>(context);
            listener.onButtonPressed();
          },
          child: const Text('Go to Next Screen'),
        ),
      ),
    );
  }
}
```

Define the Flow Coordinator that manages the screen. This needs
to be a StatefulWidget that mixes in `FlowCoordinatorMixin` and implements the
listener interface created earlier. Set your screen as `initialPages` of the flow.
Then, implement the navigation logic of the listener methods using the
`flowNavigator` to push, pop, or replace pages:

```dart
class MyFlowCoordinator extends StatefulWidget {
  const MyFlowCoordinator({super.key});

  @override
  State<MyFlowCoordinator> createState() => _MyFlowCoordinatorState();
}

class _MyFlowCoordinatorState extends State<MyFlowCoordinator>
    with FlowCoordinatorMixin
    implements MyScreenListener<MyFlowCoordinator> {
  @override
  List<Page> get initialPages => [
    const MaterialPage(key: ValueKey('my-screen'), child: MyScreen()),
  ];

  @override
  void onButtonPressed() {
    flowNavigator.push(
      MaterialPage(key: ValueKey('my-next-screen'), child: MyNextScreen()),
    );
  }
}
```

You can set this Flow Coordinator as the root of your app, or push it from another
Flow Coordinator just like a regular screen.

#### Navigating Back

Use `flowNavigator.pop()` from inside a Flow Coordinator,
or `FlowNavigator.of(context).pop()` from inside a screen,
to navigate back to the previous screen in the navigation stack. This ensures that
the correct screen/flow is popped even in case the previous screen is managed by
a different Flow Coordinator.

```dart
class MyNextScreen extends StatelessWidget {
  const MyNextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Next Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            FlowNavigator.of(context).pop();
          },
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}
```

Android back button handling is automatically delegated to the topmost navigator
— no additional configuration is needed.

### Deep Link Handling

Override the `onNewRouteInformation` method of your Flow
Coordinator's FlowCoordinatorMixin to handle incoming deep links:

```dart
/// State of the MyFlowCoordinator plain StatefulWidget.
class _MyFlowCoordinatorState extends State<MyFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) async {
    if (routeInformation.uri.pathSegments.firstOrNull == 'next') {
      flowNavigator.push(
        MaterialPage(key: ValueKey('my-next-screen'), child: MyNextScreen()),
      );
    }
    return SynchronousFuture(null);
  }
}
```

Note, return a `SynchronousFuture` if the deep link can be handled synchronously
to avoid waiting for the next microtask to schedule the build.

#### Nested Routing

If part of the deep link should be handled by a child Flow Coordinator,
return a `RouteInformation` object from the `onNewRouteInformation` that
contains the remaining part of the deep link. The child Flow Coordinator will
receive it in its own `onNewRouteInformation` method.

In the example below, the `HomeFlowCoordinator` routes to either the
`BookFlowCoordinator` or the `SettingsScreen` based on the first path segment.
It then forwards the remaining path segments to the child Flow Coordinator
by returning a new `RouteInformation` object. The `BookFlowCoordinator`
handles the remaining path segments to show either the list of books or
the details of a specific book.

```dart
/// State of the HomeFlowCoordinator StatefulWidget.
class _HomeFlowCoordinatorState extends State<HomeFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) async {
    switch (routeInformation.uri.pathSegments.firstOrNull) {
      case 'books':
        flowNavigator.setPages([
          MaterialPage(key: ValueKey('books'), child: BookFlowCoordinator()),
        ]);
      case 'settings':
        flowNavigator.setPages([
          MaterialPage(key: ValueKey('settings'), child: SettingsScreen()),
        ]);
    }
    final childRouteInformation = RouteInformation(
      uri: Uri(pathSegments: routeInformation.uri.pathSegments.sublist(1)),
    );
    return SynchronousFuture(childRouteInformation);
  }
}

/// State of the BookFlowCoordinator plain StatefulWidget.
class _BookFlowCoordinatorState extends State<BookFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final bookID = routeInformation.uri.pathSegments.firstOrNull;
    flowNavigator.setPages([
      MaterialPage(key: ValueKey('books-list'), child: BooksListScreen()),
      if (bookID != null)
        MaterialPage(
          key: ValueKey('book-$bookID'),
          child: BookDetailScreen(bookID: bookID),
        ),
    ]);
    return SynchronousFuture(null);
  }
}
```

### Updating the Browser URL

Wrap your screen widgets with `FlowRouteScope` to update the browser URL when navigating
between screens. Set `routeInformation` to the desired URL for each screen. The
browser's address bar will reflect the URL of the topmost `FlowRouteScope` in
the navigation stack, even when navigating back using in-app or Android back buttons.

```dart
/// State of the MyFlowCoordinator plain StatefulWidget.
class _MyFlowCoordinatorState extends State<MyFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) async {
    flowNavigator.setPages([
      MaterialPage(
        key: ValueKey('my-screen'),
        child: FlowRouteScope(
          // Update URL to '/' when MyScreen is active.
          routeInformation: RouteInformation(uri: Uri()),
          child: MyScreen(),
        ),
      ),
      if (routeInformation.uri.pathSegments.firstOrNull == 'next')
        MaterialPage(
          key: ValueKey('my-next-screen'),
          FlowRouteScope(
            // Update URL to '/next' when MyNextScreen is active.
            routeInformation: RouteInformation(
              uri: Uri(pathSegments: ['next']),
            ),
            child: MyNextScreen(),
          ),
        ),
    ]);
    return SynchronousFuture(null);
  }
}
```

### Tabbed Navigation with Nested Routing

For layouts where multiple flow coordinators coexist — such as a navigation bar
with persistent sub-flows — you must use `FlowRouteScope` to explicitly specify
the route information and active state of each child flow coordinator.
This has the following effects:

- **Deep Link Filtering:** It controls deep link propagation by
conditionally forwarding route updates to the child subtree only when they match
the specified `routeInformation`.
- **Updating the Browser URL:** When the route is `isActive`, its
`routeInformation` is combined with ancestor routes and reported to the platform
to update the browser's address bar or save state restoration data.
- **Back Button Handling:** Back button events are only delivered to the child
subtree if `isActive` is true.

```dart
enum HomeTab { books, settings }

/// State of the HomeFlowCoordinator StatefulWidget.
class _HomeFlowCoordinatorState extends State<HomeFlowCoordinator>
    with FlowCoordinatorMixin
    implements HomeScreenListener<HomeFlowCoordinator> {
  @override
  List<Page> get initialPages => [_buildHomePage(HomeTab.books)];

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) async {
    // 1. Parse the first segment to determine the active tab.
    final pathSegments = routeInformation.uri.pathSegments;
    final selectedTab = switch (pathSegments.firstOrNull) {
      'books' => HomeTab.books,
      'settings' => HomeTab.settings,
      _ => HomeTab.books,
    };

    // 2. Update the navigation stack to show the correct tab.
    flowNavigator.setPages([_buildHomePage(selectedTab)]);

    // 3. Forward the remaining URI segments to the child flow.
    final childRoute = RouteInformation(
      uri: Uri(pathSegments: pathSegments.skip(1).toList()),
    );
    return SynchronousFuture(childRoute);
  }

  void _onTabSelected(HomeTab tab) {
    flowNavigator.setPages([_buildHomePage(tab)]);
  }

  Page _buildHomePage(HomeTab currentTab) {
    return MaterialPage(
      child: HomeScreen(
        selectedTab: currentTab,
        tabBuilder: (context, tab) => switch (tab) {
          HomeTab.books => FlowRouteScope(
            // Only the active tab responds to back buttons & reports URLs.
            isActive: currentTab == HomeTab.books,
            routeInformation: RouteInformation(uri: Uri(path: 'books')),
            child: const BooksFlowCoordinator(),
          ),
          HomeTab.settings => FlowRouteScope(
            isActive: currentTab == HomeTab.settings,
            routeInformation: RouteInformation(uri: Uri(path: 'settings')),
            child: const SettingsScreen(),
          ),
        },
      ),
    );
  }
}
```

## Common Issues and Solutions

### Navigation Animations Not Working

Ensure that each Page you push to the `flowNavigator` has a unique LocalKey. This
allows the Navigator widget used under the hood to correctly identify pages and
apply navigation animations.
