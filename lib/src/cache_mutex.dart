import 'debug.dart';

/// Cache mutex that provides lock mechanism for delaying 
/// concurrent modification (deletion of entries due to GC).
class CacheMutex {
  /// Create new mutex.
  CacheMutex({
    this.onLock,
    this.onUnlock,
  });

  /// Lock callback.
  final void Function()? onLock;

  /// Unlock callback.
  final void Function()? onUnlock;

  /// Current locks count.
  var _locksCount = 0;

  /// Whether mutex is locked.
  bool get isLocked => _locksCount > 0;

  /// Lock mutex.
  void lock() {
    debugPrint('CacheMutex.lock ($_locksCount + 1)');
    if (++_locksCount == 1)
      onLock?.call();
  }

  /// Unlock mutex.
  void unlock() {
    debugPrint('CacheMutex.unlock ($_locksCount - 1)');
    if (!isLocked)
      return;

    if (--_locksCount == 0)
      onUnlock?.call();
  }
}
