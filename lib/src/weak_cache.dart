import 'dart:collection';

import 'package:meta/meta.dart';

import 'cache_mutex.dart';
import 'cache_state.dart';
import 'cache_strong_snapshot.dart';
import 'expando_compatible/expando_compatible.dart';


/// Weak cache that uses weak references for holding values.
/// 
/// You can use it to hold an object in cache while it's in usage, cache will
/// automatically remove it when it's no longer referenced.
/// 
/// Does not work on numbers, strings, booleans, records, `null`, `dart:ffi`
/// pointers, `dart:ffi` structs, or `dart:ffi` unions.
class WeakCache<K, V extends Object> with MapBase<K, V> implements Map<K, V> {
  /// Create new weak cache.
  WeakCache() : super() {
    if (!expandoCompatible<V>())
      throw ArgumentError.value(
        V,
        'Values type cannot be a string, number, boolean, record, null, '
        'Pointer, Struct or Union'
      );
  }

  /// Clear remove queue when state mutex unlocks.
  static void _onMutexUnlock<K, V extends Object>(
    CacheStateSnapshot<K, V> stateSnapshot,
  ) {
    final CacheStateSnapshot(:removeQueue) = stateSnapshot;
    while (removeQueue.isNotEmpty)
      CacheState.removeCacheEntryStatic(
        (
          mutex: null,
          snapshot: stateSnapshot,
          reference: removeQueue.removeLast(),
        ),
      );
  }

  late final _state = CacheState<K, V>(
    CacheMutex(onUnlock: () => _onMutexUnlock(_stateSnapshot)),
  ); 

  CacheStateSnapshot<K, V> get _stateSnapshot => _state.snapshot;

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
