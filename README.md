Weak cache that uses weak references for holding values.

This package is useful in cases when you want to hold an object in cache
while it's in usage and accessible and remove it when it's no longer needed.

For example you can hold description object in cache while traversing deep into
nested views and it eventually will be removed when you leave all related pages.

## Features

* Uses `WeakReference` for storing values.
* Implements full `Map<K, V>` interface.

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
