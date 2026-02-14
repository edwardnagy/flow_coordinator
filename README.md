A navigation and routing API that organizes screens into *user flows*, using the
Flow Controller (Coordinator) pattern.

![Flow Coordinator Illustration](https://github.com/user-attachments/assets/b356c195-48a8-4f36-9415-8d9344f5324d)

## What Is a User Flow?

A user flow is an ordered sequence of screens that complete a goal. A flow
coordinator owns the navigation rules for its screens, including any sub-flows.
Common examples:

- **Checkout:** cart → delivery options → payment → review → confirmation.
- **Password reset:** request link → verify code → set new password → success.
- **Profile setup:** create account → upload avatar → pick preferences → done.

## Features

- Reuse screens and flows across different parts of your app.
- Separate navigation logic from UI code.
- Handle deep linking and nested routing modularly.
- Update the browser URL to reflect the current route.
- Restore app state after termination.
- Guard routes — for example, redirect to login if unauthenticated.
- Support tabbed navigation with persistent sub-flows.
- Preserve compatibility with the `Navigator` API.

## Getting Started

Set the `routerConfig` of `MaterialApp.router` (or `CupertinoApp.router`) to a
`FlowCoordinatorRouter`, and provide a builder for the root flow coordinator:

```dart
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

- [Navigating Between Screens](#navigating-between-screens)
- [Deep Link Handling](#deep-link-handling)
- [Updating the Browser URL](#updating-the-browser-url)
- [Tabbed Navigation with Nested Routing](#tabbed-navigation-with-nested-routing)

A complete example app is available in the [example](example/) directory. It
demonstrates all the navigation requirements identified by the Flutter team in
their [Routing API Usability Research](https://github.com/flutter/uxr/blob/master/docs/Flutter-Routing-API-Usability-Research.md)
as “important yet difficult to implement”.

### Navigating Between Screens

Define an interface for your screen's navigation events. The interface must
implement `FlowCoordinatorMixin`:

```dart
abstract interface class MyScreenListener<T extends StatefulWidget>
    implements FlowCoordinatorMixin<T> {
  void onButtonPressed();
}
```

In the screen, retrieve the nearest flow coordinator that implements the
listener using `FlowCoordinator.of`:

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
            FlowCoordinator.of<MyScreenListener>(context).onButtonPressed();
          },
          child: const Text('Go to Next Screen'),
        ),
      ),
    );
  }
}
```

Create a `StatefulWidget` that mixes in `FlowCoordinatorMixin` and implements
the listener. Override `initialPages` to set the starting screen, then use
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

A flow coordinator can be set as the root of the app or pushed from another flow
coordinator like a regular screen.

#### Navigating Back

Use `flowNavigator.pop()` from inside a flow coordinator, or
`FlowNavigator.of(context).pop()` from inside a screen. The correct screen or
flow is popped even when the previous screen belongs to a different flow
coordinator.

```dart
class MyNextScreen extends StatelessWidget {
  const MyNextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Next Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => FlowNavigator.of(context).pop(),
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}
```

Android back button handling is automatically delegated to the topmost
navigator — no additional configuration is needed.

### Deep Link Handling

Override `onNewRouteInformation` to handle incoming deep links:

```dart
class _MyFlowCoordinatorState extends State<MyFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    if (routeInformation.uri.pathSegments.firstOrNull == 'next') {
      flowNavigator.push(
        MaterialPage(key: ValueKey('my-next-screen'), child: MyNextScreen()),
      );
    }
    return SynchronousFuture(null);
  }
}
```

Return a `SynchronousFuture` when the result can be computed synchronously to
avoid waiting for the next microtask.

#### Forwarding to Child Flows

Return a `RouteInformation` from `onNewRouteInformation` to forward the
remaining path segments to a child flow coordinator. The child receives them in
its own `onNewRouteInformation`:

```dart
class _HomeFlowCoordinatorState extends State<HomeFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
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

class _BookFlowCoordinatorState extends State<BookFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
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

#### Programmatic Deep Links

Use `setNewRouteInformation` to programmatically trigger `onNewRouteInformation`
on the current flow coordinator:

```dart
void openRandomBook() {
  setNewRouteInformation(
    RouteInformation(uri: Uri(pathSegments: ['books', '42'])),
  );
}
```

### Updating the Browser URL

Wrap screen widgets with `FlowRouteScope` to report their route to the browser's
address bar. Set `routeInformation` to the desired URL segment for each screen.
The browser URL reflects the topmost active `FlowRouteScope`, including when
navigating back with in-app or Android back buttons.

> **Note:** Set `routeInformationReportingEnabled: true` on
> `FlowCoordinatorRouter` to enable browser URL updates:
>
> ```dart
> final _router = FlowCoordinatorRouter(
>   routeInformationReportingEnabled: true,
>   homeBuilder: (context) => const MyFlowCoordinator(),
> );
> ```

```dart
class _MyFlowCoordinatorState extends State<MyFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    flowNavigator.setPages([
      MaterialPage(
        key: ValueKey('my-screen'),
        child: FlowRouteScope(
          routeInformation: RouteInformation(uri: Uri()),
          child: MyScreen(),
        ),
      ),
      if (routeInformation.uri.pathSegments.firstOrNull == 'next')
        MaterialPage(
          key: ValueKey('my-next-screen'),
          child: FlowRouteScope(
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

Route information from nested flows is combined automatically — a parent
reporting `books` and a child reporting `123` produces `/books/123`. Override
`routeInformationCombiner` in your flow coordinator to customize this behavior.

### Tabbed Navigation with Nested Routing

For layouts where multiple flow coordinators coexist — such as tabs — wrap each
child in a `FlowRouteScope` to control its active state:

- **Deep link filtering:** Only the tab whose `routeInformation` matches the
incoming URL receives the deep link.
- **URL reporting:** Only the active tab's route is reported to the browser.
- **Back button scoping:** Back button events are delivered only to the active
tab.

```dart
enum HomeTab { books, settings }

class _HomeFlowCoordinatorState extends State<HomeFlowCoordinator>
    with FlowCoordinatorMixin
    implements HomeScreenListener<HomeFlowCoordinator> {
  @override
  List<Page> get initialPages => [_buildHomePage(HomeTab.books)];

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    final pathSegments = routeInformation.uri.pathSegments;
    final selectedTab = switch (pathSegments.firstOrNull) {
      'books' => HomeTab.books,
      'settings' => HomeTab.settings,
      _ => HomeTab.books,
    };

    flowNavigator.setPages([_buildHomePage(selectedTab)]);

    return SynchronousFuture(
      RouteInformation(uri: Uri(pathSegments: pathSegments.skip(1).toList())),
    );
  }

  Page _buildHomePage(HomeTab currentTab) {
    return MaterialPage(
      child: HomeScreen(
        selectedTab: currentTab,
        tabBuilder: (context, tab) => switch (tab) {
          HomeTab.books => FlowRouteScope(
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

## Troubleshooting

### Navigation Animations Not Working

Each `Page` pushed to `flowNavigator` must have a unique `LocalKey`. This allows
the `Navigator` to correctly identify pages and apply transition animations.
