/// A wrapper for a value that can only be retrieved once.
///
/// After the value is consumed, it cannot be accessed again.
class Consumable<T> {
  /// Creates a [Consumable] with the given value.
  ///
  /// The [isConsumed] parameter indicates whether the value has already been
  /// consumed.
  Consumable(
    this._value, {
    bool isConsumed = false,
  }) : _isConsumed = isConsumed;

  final T _value;
  bool _isConsumed;

  /// The value, if it has not yet been consumed.
  ///
  /// The value is marked as consumed after the first retrieval. Returns `null`
  /// on subsequent calls.
  T? consumeOrNull() {
    if (_isConsumed) return null;
    _isConsumed = true;
    return _value;
  }
}
