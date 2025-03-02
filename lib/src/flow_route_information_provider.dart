import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rxdart/subjects.dart';

import 'consumable_value.dart';

abstract class FlowRouteInformationProvider extends RouteInformationProvider {
  static FlowRouteInformationProvider? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<
        FlowRouteInformationProviderScope>();
    return scope?.value;
  }

  ConsumableValue<RouteInformation>? get childConsumableValue;

  // TODO: Use a valueNotifier instead because the current value can always be accessed by the getter.
  // Listeners just need to be notified when the value changes.
  /// The value that child (nested) flow coordinators can consume.
  Stream<ConsumableValue<RouteInformation>> get childConsumableValueStream;
}

class RootFlowRouteInformationProvider extends PlatformRouteInformationProvider
    implements FlowRouteInformationProvider {
  RootFlowRouteInformationProvider({required super.initialRouteInformation}) {
    addListener(_onValueUpdated);
  }

  late final _childConsumableValueController =
      BehaviorSubject<ConsumableValue<RouteInformation>>.seeded(
    ConsumableValue(value),
  );

  @override
  ConsumableValue<RouteInformation>? get childConsumableValue =>
      _childConsumableValueController.value;

  @override
  Stream<ConsumableValue<RouteInformation>> get childConsumableValueStream =>
      _childConsumableValueController.stream;

  @override
  void dispose() {
    removeListener(_onValueUpdated);
    _childConsumableValueController.close();
    super.dispose();
  }

  void _onValueUpdated() {
    _childConsumableValueController.add(ConsumableValue(value));
  }

  bool _routeInformationReportingTaskScheduled = false;

  /// The route information that is pending to be reported.
  RouteInformation? _pendingRouteInformation;

  void _scheduleRouteInformationReportingTask() {
    if (_routeInformationReportingTaskScheduled) {
      return;
    }
    _routeInformationReportingTaskScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback(
      _reportRouteInformation,
      debugLabel: 'RootFlowRouteInformationProvider.reportRouteInfo',
    );
  }

  void _reportRouteInformation(Duration timestamp) {
    assert(_routeInformationReportingTaskScheduled);
    _routeInformationReportingTaskScheduled = false;

    if (_pendingRouteInformation case final pendingRouteInformation?) {
      final isNewRouteInformation = pendingRouteInformation.uri != value.uri;
      if (isNewRouteInformation) {
        // TODO: Add logging for the reported route information.
        super.routerReportsNewRouteInformation(pendingRouteInformation);
      }
      _pendingRouteInformation = null;
    }
  }

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    _pendingRouteInformation = routeInformation;
    _scheduleRouteInformationReportingTask();
  }
}

class ChildFlowRouteInformationProvider extends FlowRouteInformationProvider
    with ChangeNotifier {
  ChildFlowRouteInformationProvider({
    required RouteInformation initialValue,
  }) : _value = initialValue;

  /// Subscribes to the child consumable value stream of the parent provider.
  StreamSubscription? _valueSubscription;

  // TODO: This subscribes to the parent's child consumable value stream.
  // But [ChildRouteInformationFilter] has a workaround for this.
  // Can this be improved somehow for better maintainability? Maybe moved somewhere else?
  void registerParentProvider(FlowRouteInformationProvider? parent) {
    if (parent?.childConsumableValue case final childConsumableValue?) {
      _onValueReceivedFromParent(childConsumableValue);
    }
    _valueSubscription?.cancel();
    _valueSubscription =
        parent?.childConsumableValueStream.listen(_onValueReceivedFromParent);
  }

  final _childConsumableValueController =
      BehaviorSubject<ConsumableValue<RouteInformation>>();

  @override
  RouteInformation get value => _value;
  RouteInformation _value;
  set value(RouteInformation newValue) {
    _value = newValue;
    notifyListeners();
  }

  @override
  ConsumableValue<RouteInformation>? get childConsumableValue =>
      _childConsumableValueController.valueOrNull;

  @override
  Stream<ConsumableValue<RouteInformation>> get childConsumableValueStream =>
      _childConsumableValueController.stream;

  void _onValueReceivedFromParent(
    ConsumableValue<RouteInformation> consumableValue,
  ) {
    final value = consumableValue.getAndConsumeOrNull();
    if (value == null) return;

    _value = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _valueSubscription?.cancel();
    _childConsumableValueController.close();
    super.dispose();
  }

  void setChildValue(RouteInformation childValue) {
    _childConsumableValueController.add(ConsumableValue(childValue));
  }
}

class FlowRouteInformationProviderScope extends InheritedWidget {
  const FlowRouteInformationProviderScope(
    this.value, {
    super.key,
    required super.child,
  });

  final FlowRouteInformationProvider value;

  @override
  bool updateShouldNotify(FlowRouteInformationProviderScope oldWidget) =>
      value != oldWidget.value;
}
