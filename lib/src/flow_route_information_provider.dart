import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rxdart/subjects.dart';

abstract class FlowRouteInformationProvider extends RouteInformationProvider {
  /// The value that child (nested) flow coordinators can consume.
  Stream<ConsumableValue<RouteInformation>> get childConsumableValueStream;

  ConsumableValue<RouteInformation>? get childConsumableValue;
}

/// A wrapper for values that ensures single-use consumption.
///
/// Used to encapsulate values, such as route information, that should
/// only be processed once. After being consumed, the value is marked
/// as consumed and ignored by other listeners.
///
/// Example:
/// ```dart
/// final value = ConsumableValue('Navigate to home');
/// if (!value.isConsumed) {
///   print(value.value); // Use the value.
///   value.isConsumed = true; // Mark as consumed.
/// }
/// ```
class ConsumableValue<T> {
  /// Creates a consumable value.
  ConsumableValue(this.value, {this.isConsumed = false});

  /// The wrapped value.
  final T value;

  /// Whether this value has been consumed.
  ///
  /// Once consumed, it should not be used again.
  bool isConsumed;

  T? getAndConsumeOrNull() {
    if (isConsumed) return null;
    isConsumed = true;
    return value;
  }
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
    required this.parent,
    required this.routeInformationProcessor,
    required RouteInformation initialValue,
  }) : _value =
            parent.childConsumableValue?.getAndConsumeOrNull() ?? initialValue {
    _consumableValueSubscription =
        parent.childConsumableValueStream.listen(_onValueReceivedFromParent);
  }

  final FlowRouteInformationProvider parent;
  final RouteInformationProcessor routeInformationProcessor;

  StreamSubscription? _consumableValueSubscription;

  final _childConsumableValueController =
      BehaviorSubject<ConsumableValue<RouteInformation>>();

  @override
  RouteInformation get value => _value;
  RouteInformation _value;

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
    if (value == null || value == _value) return;

    _value = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _consumableValueSubscription?.cancel();
    _childConsumableValueController.close();
    super.dispose();
  }

  void setChildValue(RouteInformation childValue) {
    if (childValue == _childConsumableValueController.valueOrNull?.value) {
      return;
    }
    _childConsumableValueController.add(ConsumableValue(childValue));
  }
}
