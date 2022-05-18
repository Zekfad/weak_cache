import 'dart:collection';


/// Weak cache that uses weak references for holding values.
/// It's useful in cases when you want to hold an object in cache while it's in
/// usage and remove it when it's no longer accessible.
/// 
/// Values ([V]) must not be a number, a string, a boolean, `null`, a `dart:ffi`
/// pointer, a `dart:ffi` struct, or a `dart:ffi` union.
class WeakCache<K, V extends Object> with MapMixin<K, V> implements Map<K, V> {
  /// Create new weak cache.
  WeakCache() : super() {
    if (
      V == num ||
      V == int ||
      V == double ||
      V == String ||
      V == bool||
      V == Null
    ) {
      throw ArgumentError.value(V, 'Invalid type for values');
    }
  }

  /// Backend of the cache. 
  final Map<K, WeakReference<V>> cache = {};

  /// Finalizer that removes objects from cache table. 
  late final cacheFinalizer = Finalizer<WeakReference<V>>(_removeCacheEntry);

  /// Removes cache entry from table and detaches finalizer.
  void _removeCacheEntry(WeakReference<V> reference) {
    cacheFinalizer.detach(reference);
    cache.removeWhere((key, value) => value == reference);
  }

  @override
  Iterable<K> get keys => cache.keys;

  @override
  V? operator[](Object? key) => cache[key]?.target;

  @override
  void operator[]=(K key, V value) {
    final cached = cache[key];
    if (cached != null) {
      _removeCacheEntry(cached);
    }
    final reference = cache[key] = WeakReference<V>(value);
    cacheFinalizer.attach(value, reference, detach: reference);
  }

  @override
  V? remove(Object? key) {
    final reference = cache[key];
    if (reference == null) {
      return null;
    }
    cacheFinalizer.detach(reference);
    return reference.target;
  }

  @override
  void clear() {
    for (final reference in cache.values) {
      cacheFinalizer.detach(reference);
    }
    cache.clear();
  }
}
