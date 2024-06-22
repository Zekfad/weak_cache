## 2.1.2

- Optimize cache entry removal performance.
  > Previously `removeWhere` was used which caused iteration of whole cache set
  > on every removal.
  > Now additional `Expando` is used to map Weak references to their keys.

## 2.1.1

- Fix web release target compilation.

## 2.1.0

- Add `weak_cache.utils` library with `expandoCompatible` utility function.
- Update type check, to correctly detect all disallowed values types.

## 2.0.1

- Remove dependency on [`package:disposed`](https://pub.dev/packages/disposed).
- Fix "leak" of nulled Weak references, if objects where added while iterating.
  > Generally you should not modify cache while iterating it, but this is
  > technically possible.

## 2.0.0

- Requires Dart 3.0.0
- **BREAKING**: remove `WeakCache.cacheFinalizer`.
- Fix memory leak caused by instance member finalizer.
- Optimize `containsValue`.
- Fix concurrent modification error, now using keys/values/entries
  will temporarily prevent them from being garbage collected.

## 1.0.0

- Initial version.
