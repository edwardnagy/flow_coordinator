/// A wrapper for a value that can only be retrieved once.
///
/// After the value is consumed, it cannot be accessed again.
class Consumable<T> {
  /// Creates a [Consumable] with the given [_value].
  ///
  /// The [isConsumed] parameter indicates whether the value has already been
  /// consumed.
  Consumable(
    this._value, {
    bool isConsumed = false,
  }) : _isConsumed = isConsumed;

  final T _value;
  bool _isConsumed;

  /// Returns the value if it has not been consumed, then marks it as consumed.
  ///
  /// Returns `null` if the value has already been consumed.
  T? consumeOrNull() {
    if (_isConsumed) return null;
    _isConsumed = true;
    return _value;
  }
}
