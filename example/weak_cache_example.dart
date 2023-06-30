import 'dart:async';

import 'package:weak_cache/src/debug.dart' show kDebug;
import 'package:weak_cache/weak_cache.dart';


Future<void> main() async {
  kDebug = true;

  // Create cache
  final cache = WeakCache<int, Object>();

  // Create some objects
  Object? someObject = Object();
  Object? someObject2 = Object();

  final someObjectRef =  WeakReference(someObject);
  final someObject2Ref =  WeakReference(someObject2);

  // Add them to cache
  cache[0] = someObject;
  cache[1] = someObject2;

  // Check they are in the cache
  assert(identical(cache[0], someObject), 'Cached object must be identical');
  assert(identical(cache[1], someObject2), 'Cached object must be identical');

  // Track to not repeat print's messages
  var messageRef1Shown = false;
  var messageCache1Shown = false;
  var messageRef2Shown = false;
  var messageCache2Shown = false;

  // Remove last reference to the first object
  someObject = null;

  while (true) {
    // 1st ref
    if (someObjectRef.target == null && !messageRef1Shown) {
      print('Object 1 is garbage collected.');
      messageRef1Shown = true;
    }

    // 1st cache
    if (cache[0] == null && !messageCache1Shown) {
      print('Object 1 is no longer in cache.');
      messageCache1Shown = true;
    }

    // 2nd ref
    if (someObject2Ref.target == null && !messageRef2Shown) {
      print('Object 2 is garbage collected.');
      messageRef2Shown = true;
    }

    // 2nd cache
    if (cache[1] == null && !messageCache2Shown) {
      print('Object 2 is no longer in cache.');
      messageCache2Shown = true;
    }

    // 1st object is now destroyed, so we can destroy the 2nd
    if (messageRef1Shown && messageCache1Shown) {
      someObject2 = null;
    }

    assert(
      messageRef1Shown == messageCache1Shown && messageRef2Shown == messageCache2Shown,
      'cache and weak reference in default conditions should be cleaned at the same time',
    );

    assert(
      (messageRef1Shown && messageRef2Shown && messageCache1Shown && messageCache2Shown) == cache.isEmpty,
      'cache should be empty when both object are destroyed',
    );

    if (cache.isEmpty)
      break;

    // Feed memory until we GC both objects.
    print('Feed memory to force GC');
    // ignore: unused_local_variable
    final bigChunkOfData = '0' * 1024 * 1024 * 5; // about 5mb of data.
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
}
