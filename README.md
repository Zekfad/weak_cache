# Weak Cache

[![pub package](https://img.shields.io/pub/v/weak_cache.svg)](https://pub.dev/packages/weak_cache)
[![package publisher](https://img.shields.io/pub/publisher/weak_cache.svg)](https://pub.dev/packages/weak_cache/publisher)

Weak cache is a `Map` implementation that uses `WeakReference`s for holding
values and `Finalizer` to manage it's storage.

You can use this to cache data for a small amount of time until next garbage
collection cycle.

> Note: Values cannot be numbers, strings, booleans, records, `null`,
> `dart:ffi` pointers, `dart:ffi` structs, or `dart:ffi` unions.

## Features

* Uses `WeakReference` for storing values.
* Uses `Finalizer` to remove objects from internal storage upon their deletion.
* Allows you iterate over keys/values.
  > While iterating, all stored values are temporarily made into strong
  > references, to prevent concurrent edit of storage, while iterating over it.
* Optimized `containsValue` via internal managed `Expando`.
* Implements full `Map<K, V>` interface.
* `WeakCache` itself can be safely garbage collected and doesn't hold unto any
  stored data.

## Usage

Create cache, add values, and they'll be removed once there no more strong 
references to them.

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
