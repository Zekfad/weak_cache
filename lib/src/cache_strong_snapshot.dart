import 'dart:collection';

import 'debug.dart';


/// Aggregation of data required for [CacheStrongSnapshot._finalizer] callback.
typedef CacheStrongSnapshotFinalizerArgument<T> = ({
  List<T> references,
  void Function()? callback,
});

/// Snapshot of cache contents that creates strong lint for every accessible
/// element.
/// This class is essential part that makes iteration on weak cache possible.
class CacheStrongSnapshot<K, V extends Object> with ListBase<(K, V)> {
  /// Create new snapshot from weak cache.
  /// Additionally accepts [onDispose] callback that will be executed upon
  /// this snapshot garbage collected.
  CacheStrongSnapshot(
    Map<K, WeakReference<V>> cache, [
      void Function()? onDispose,
    ]
  ) :
    _values = [
      for (final MapEntry(:key, value: reference) in cache.entries)
        if (reference.target case final value?)
          (key, value),
    ] {
    _finalizer.attach(
      this, (
        references: _values,
        callback: onDispose,
      ),
      detach: _values,
    );
  }

  /// [Finalizer] that removes references when snapshot is destroyed.
  static final _finalizer = Finalizer<CacheStrongSnapshotFinalizerArgument<Object>>(
    _clearReferences,
  );

  /// [_finalizer] callback.
  static void _clearReferences<T>(CacheStrongSnapshotFinalizerArgument<T> argument) {
    debugPrint('Strong snapshot was garbage collected');
    final (:references, :callback) = argument;
    _finalizer.detach(references);
    references.clear();
    callback?.call();
  }

  /// Strong references container.
  final List<(K, V)> _values;

  /// Keys of snapshot cache.
  Iterable<K> get keys  => _values.map((e) => e.$1);

  /// Values of snapshot cache.
  Iterable<V> get values => _values.map((e) => e.$2);

  @override
  int get length => _values.length;
  
  @override
  set length(int newLength) => _values.length = newLength;

  @override
  void add((K, V) element) => _values.add(element);

  @override
  void addAll(Iterable<(K, V)> iterable) => _values.addAll(iterable);

  @override
  (K, V) operator [](int index) => _values[index];

  @override
  void operator []=(int index, (K, V) value) => _values[index] = value;
}
