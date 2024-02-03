import 'dart:collection';

import 'cache_mutex.dart';


/// Aggregation of [CacheState] main properties.
typedef CacheStateSnapshot<K, V extends Object> = ({
  Map<K, WeakReference<V>> cache,
  ListQueue<WeakReference<V>> removeQueue,
  Expando<bool> containsExpando,
});

/// Aggregation of [CacheState] main properties with details
/// required for deletion of entry.
typedef CacheStateSnapshotWithReference<K, V extends Object> = ({
  CacheStateSnapshot<K, V> snapshot,
  WeakReference<V> reference,
  CacheMutex? mutex,
});

/// Weak cache state, including locks, storage, concurrent modification
/// delayed queue and expando for `containsValue` optimization.
/// 
/// [add] and [remove] methods do not use [mutex] because of single threaded
/// nature of event loop.
class CacheState<K, V extends Object> {
  /// Create new state.
  CacheState(this.mutex);

  /// Mutex providing concurrent modification lock.
  final CacheMutex mutex;
  /// Actual storage of weak references.
  final cache = <K, WeakReference<V>>{};
  /// Queue for delayed concurrent modifications.
  final removeQueue = ListQueue<WeakReference<V>>();
  /// [Expando] used to optimize `containsValue` calls and bypass using
  /// of iteration.
  final containsExpando = Expando<bool>();

  /// [Finalizer] that manages [cache].
  static final cacheFinalizer = Finalizer<CacheStateSnapshotWithReference<Object?, Object>>(
    tryRemoveCacheEntryStatic,
  );

  /// Try to remove [cache] entry or delay deletion via [removeQueue]
  /// if there are some running [Iterator]s.
  static void tryRemoveCacheEntryStatic<K, V extends Object>(
    CacheStateSnapshotWithReference<K, V> argument,
  ) {
    final (
      snapshot: CacheStateSnapshot(:removeQueue),
      :reference,
      :mutex,
    ) = argument;
    if (mutex?.isLocked != true)
      return removeCacheEntryStatic(argument);
    removeQueue.addLast(reference);
  }

  /// Removes cache entry from [cache] table and detach finalizer form it.
  static void removeCacheEntryStatic<K, V extends Object>(
    CacheStateSnapshotWithReference<K, V> argument,
  ) {
    final CacheStateSnapshotWithReference(
      snapshot: CacheStateSnapshot(:cache, :containsExpando),
      :reference,
    ) = argument;
    cacheFinalizer.detach(reference);
    if (reference.target case final target?)
      containsExpando[target] = null;
    cache.removeWhere((key, value) => value == reference);
  }

  /// Get aggregation of [CacheState] main properties.
  CacheStateSnapshot<K, V> get snapshot => (
    cache: cache,
    removeQueue: removeQueue,
    containsExpando: containsExpando,
  );

  /// Create aggregation of [CacheState] properties required for value deletion.
  CacheStateSnapshotWithReference<K, V> makeSnapshotWithReference(
    WeakReference<V> reference,
  ) => (
    mutex: mutex,
    snapshot: snapshot,
    reference: reference,
  );
 
  /// Force remove [cache] entry from. 
  void removeCacheEntry(WeakReference<V> reference) =>
    removeCacheEntryStatic(makeSnapshotWithReference(reference));

  /// Add new [cache] entry and attach to [cacheFinalizer].
  void add(K key, V value) {
    final cached = cache[key];
    if (cached != null) {
      removeCacheEntry(cached);
    }
    containsExpando[value] = true;
    final reference = cache[key] = WeakReference<V>(value);
    cacheFinalizer.attach(
      value,
      makeSnapshotWithReference(reference),
      detach: reference,
    );
  }

  /// Try to remove object from cache and detach from [cacheFinalizer].
  V? remove(Object? key) {
    final reference = cache.remove(key);
    if (reference == null) {
      return null;
    }
    cacheFinalizer.detach(reference);
    if (reference.target case final target?)
      containsExpando[target] = null;
    return reference.target;
  }

  /// Detach all values from [cacheFinalizer] and clear [cache].
  void clear() {
    cache.values.forEach(cacheFinalizer.detach);
    cache.clear();
  }
}
