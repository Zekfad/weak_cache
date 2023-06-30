## 2.0.0

- Requires Dart 3.0.0
- **BREAKING**: remove `WeakCache.cacheFinalizer`.
- Fix memory leak caused by instance member finalizer.
- Optimize `containsValue`.
- Fix concurrent modification error, now using keys/values/entries
  will temporarily prevent them from being garbage collected.

## 1.0.0

- Initial version.
