import 'dart:async';

import 'package:weak_cache/weak_cache.dart';

void main() {
  // Create cache
  final cache = WeakCache<int, Object>();

  // Create some objects
  Object? someObject = Object();
  Object? someObject2 = Object();

  // Add them to cache
  cache[0] = someObject;
  cache[1] = someObject2;

  // Check they are in the cache
  print('someObject and cache[0] are the same: ${cache[0] == someObject}');

  bool firstGC = false;
  bool secondGC = false;

  // Wait until they will be GC'd.
  Timer.periodic(Duration(seconds: 1), (timer) {
    // Won't be GC'd while someObject2 (cache[2]) is alive, because
    // `if` after this one holds strong reference to someObject until it's nulled.
    if (cache[0] == null && firstGC == false) {
      print('Some object 1 has been garbage collected by that time.');
      firstGC = true;
    }

    // Remove last reference to first object by nulling someObject variable.
    if (cache[1] == null && secondGC == false) {
      print('Some object 2 has been garbage collected by that time, let\'s trash first one.');
      someObject = null;
      secondGC = true;
    }

    // Exit when cache is empty.
    if (cache.isEmpty) {
      timer.cancel();
    }

    // Feed memory until we GC both objects.
    if (!(firstGC && secondGC)) {
      print('Feed memory to force GC');
      String bigChunkOfData = '0' * 1024 * 1024 * 5; // about 5mb of data.
    }
  });
}
