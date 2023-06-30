import 'dart:async';

import 'package:disposed/disposed.dart';

import 'debug.dart';


/// Cache mutex that provides lock mechanism for delaying 
/// concurrent modification.
class CacheMutex extends DisposableContainer {
  @override
  List<Disposable> get disposables => [ _controller, ];

  /// Controller for [stream] of locked states.
  final _controller = DisposableStreamController(
    StreamController<bool>(),
  );

  /// Current locks count.
  var _locksCount = 0;

  /// Whether mutex is locked.
  bool get isLocked => _locksCount > 0;

  /// Stream exposing changes in [isLocked].
  Stream<bool> get stream => _controller.controller.stream;

  /// Lock mutex and announce change via [stream].
  void lock() {
    debugPrint('CacheMutex.lock (was $_locksCount)');
    _locksCount++;
    _controller.controller.add(isLocked);
  }

  /// Unlock mutex and announce change via [stream].
  void unlock() {
    debugPrint('CacheMutex.unlock (was $_locksCount)');
    if (isLocked) {
      _locksCount--;
      _controller.controller.add(isLocked);
    }
  }
}
