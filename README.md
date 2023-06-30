# Weak Cache

Weak cache is `Map` implementation that uses `WeakReference`s for holding values
and `Finalizer` to manage it's storage.

This package is useful in cases when you want to hold an object in cache
while it's in usage and accessible and remove it when it's no longer needed.

You can use it to cache data (e.g. API responses) for a small amount of time
(until nex garbage collection cycle).

For example you can hold description object in cache while traversing deep into
nested views and it eventually will be removed when you lose all references
to it.

## Features

* Uses `WeakReference` for storing values.
* Uses `Finalizer` to remove objects from internal storage.
* Allows you iterate over keys/values (while iterating, all stored values are
  temporarily made into strong references, to prevent concurrent edit of storage
  while iterating over it).
* Optimized `containsValue` via internal managed `Expando`.
* Implements full `Map<K, V>` interface.
* WeakCache itself can be safely garbage collected and doesn't produce memory
  leaks.

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

## Issues

If you encounter issues, here are some tips for debug, if nothing helps report
to [issue tracker on GitHub](https://github.com/Zekfad/weak_cache/issues):

* It's possible that GC cycles are not yet touched objects and `Finalizer`
  is not executed it's callback.
* Check that your objects are not strongly references elsewhere.
* Set `kDebug` to `true` in [lib/src/debug.dart](lib/src/debug.dart).
  * Using iteration should eventually print
    `Strong snapshot was garbage collected` to console, lookout for
    messages like `CacheMutex.unlock (was X)` and
    `CacheMutex.lock (was X)` to track concurrent write locks status.
  * If you expect `WeakCache` to be destroyed by GC lookout for
    `Mutex stream closed.` message.
  * Try to feed memory like in example to force GC.
