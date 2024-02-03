# Weak Cache

Weak cache is a `Map` implementation that uses `WeakReference`s for holding
values and `Finalizer` to manage it's storage.

You can use it to cache data (e.g. API responses) for a small amount of time
(until next garbage collection cycle).


## Features

* Uses `WeakReference` for storing values.
* Uses `Finalizer` to remove objects from internal storage upon their deletion.
* Allows you iterate over keys/values.
  > While iterating, all stored values are temporarily made into strong
  > references, to prevent concurrent edit of storage, while iterating over it.
* Optimized `containsValue` via internal managed `Expando`.
* Implements full `Map<K, V>` interface.
* WeakCache itself can be safely garbage collected and doesn't hold unto any
  stored.

## Usage

Just create cache, add some values, and they'll be removed when all other
strong references to they are lost.
```dart
// ID - Object cache
final cache = WeakCache<int, Object>();

Object? obj = Object();
cache[0] = obj;
// ...
obj = null;
// ...
// After garbage collection cache[0] will be removed.
cache[0] == null;
```

See [example](example/weak_cache_example.dart) for detailed test case.
