import 'dart:collection';

import 'package:meta/meta.dart';

import 'cache_state.dart';
import 'cache_strong_snapshot.dart';
import 'debug.dart';


/// Weak cache that uses weak references for holding values.
/// It's useful in cases when you want to hold an object in cache while it's in
/// usage and remove it when it's no longer accessible.
/// 
/// Values ([V]) must not be a number, a string, a boolean, `null`, a `dart:ffi`
/// pointer, a `dart:ffi` struct, or a `dart:ffi` union.
class WeakCache<K, V extends Object> with MapBase<K, V> implements Map<K, V> {
  /// Create new weak cache.
  WeakCache() : super() {
    if (
      V == num ||
      V == int ||
      V == double ||
      V == String ||
      V == bool||
      V == Null
    )
      throw ArgumentError.value(V, 'Invalid type for values');
    _state.mutex.stream.listen(
      _createStreamListener(this._state.snapshot),
      onDone: !kDebug ? null : () {
        debugPrint('Mutex stream closed.');
      },
    );
  }

  static void Function(bool) _createStreamListener<K, V extends Object>(
    CacheStateSnapshot<K, V> stateSnapshot,
  ) =>
    (isLocked) {
      if (!isLocked) {
        final CacheStateSnapshot(:removeQueue) = stateSnapshot;
        while (removeQueue.isNotEmpty)
          CacheState.removeCacheEntryStatic(
            (
              snapshot: stateSnapshot,
              isLocked: false,
              reference: removeQueue.removeLast(),
            ),
          );
      }
    };

  final _state = CacheState<K, V>(); 

  @Deprecated(
    'Do not use cache directly, as it can change at any time and likely '
    'will produce unexpected result with ConcurrentModificationError errors. '
    'This property retained for backwards compatibility.'
  )
  @internal
  Map<K, WeakReference<V>> get cache => _state.cache;

  /// Usage of [containsKey] is __discouraged__.
  /// 
  /// You should use `operator[]` and store value, then check it for `null`.
  /// Otherwise it's possible that object would be garbage collected between
  /// call for [containsKey] and actual usage.
  /// 
  /// `true` value returned from this function _only_ guarantees that value
  /// _was_ in cache at exact moment of check, but it could be gone right after
  /// that.
  @override
  bool containsKey(Object? key) => this[key] != null;

  @override
  bool containsValue(Object? value) => switch(value) {
    final value? => _state.containsExpando[value] ?? false,
    _ => false,
  };

  @override
  Iterable<V> get values {
    _state.mutex.lock();
    return CacheStrongSnapshot(
      _state.cache,
      _state.mutex.unlock,
    ).values;
  }

  @override
  Iterable<K> get keys {
    _state.mutex.lock();
    return CacheStrongSnapshot(
      _state.cache,
      _state.mutex.unlock,
    ).keys;
  }

  @override
  bool get isNotEmpty => _state.cache.isNotEmpty;

  @override
  bool get isEmpty => _state.cache.isEmpty;

  @override
  V? operator[](Object? key) => _state.cache[key]?.target;

  @override
  void operator[]=(K key, V value) => _state.add(key, value);

  @override
  V? remove(Object? key) => _state.remove(key);

  @override
  void clear() => _state.clear();
}
