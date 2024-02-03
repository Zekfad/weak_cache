import 'dart:async';

import 'package:test/test.dart';
import 'package:weak_cache/src/debug.dart';
import 'package:weak_cache/weak_cache.dart';


Future<void> parallelLoops(
  Iterable<FutureOr<bool> Function()> functions, {
    Duration delay = const Duration(milliseconds: 15),
  }
) => Future.wait([
  for (final function in functions)
    Future.doWhile(() async {
      await Future<void>.delayed(delay);
      return function();
    }),
]);

class _Int {
  _Int(this.i);
  final int i;
  @override
  String toString() => i.toString();
}


void main() {
  kDebug = true;

  group('Test Weak Cache', () {
    test('held objects should be garbage collected and removed from cache', () async {
      final events = <String>[];

      final cache = WeakCache<int, Object>();

      // Create some objects
      Object? someObject = Object();
      Object? someObject2 = Object();

      final _someObjectRef = WeakReference(someObject);
      final _someObject2Ref = WeakReference(someObject2);

      // Add them to cache
      cache[0] = someObject;
      cache[1] = someObject2;

      final _someObjectRefDone = expectAsync0<bool>(() {
        events.add('some object');
        return false;
      });

      final _someObject2RefDone = expectAsync0<bool>(() {
        events.add('some object 2');
        return false;
      });

      expect(identical(cache[0], someObject), isTrue);
      expect(identical(cache[0], _someObjectRef.target), isTrue);
      expect(identical(cache[1], someObject2), isTrue);
      expect(identical(cache[1], _someObject2Ref.target), isTrue);

      someObject = null;
      someObject2 = null;

      await parallelLoops([
        () {
          // ignore: unused_local_variable
          final bigChunkOfData = '0' * 1024 * 1024 * 50; // about 50mb of data.
          if (_someObjectRef.target != null)
            return true;
          return _someObjectRefDone();
        },
        () {
          // ignore: unused_local_variable
          final bigChunkOfData = '0' * 1024 * 1024 * 50; // about 50mb of data.
          if (_someObject2Ref.target != null)
            return true;
          return _someObject2RefDone();
        },
      ]);

      expect(cache[0], isNull);
      expect(_someObjectRef.target, isNull);
      expect(cache[1], isNull);
      expect(_someObject2Ref.target, isNull);
      expect(
        events,
        unorderedEquals([
          'some object',
          'some object 2',
        ]),
      );
    });

    test('should not prevent itself from garbage collection', () async {
      final events = <String>[];

      WeakCache<int, Object>? cache = WeakCache<int, Object>();
      final _cacheRef = WeakReference(cache);

      // Create some objects
      Object? someObject = Object();
      final _someObjectRef =  WeakReference(someObject);

      // Add them to cache
      cache[0] = someObject;

      final _cacheRefDone = expectAsync0<bool>(() {
        events.add('cache');
        return false;
      });

      final _someObjectRefDone = expectAsync0<bool>(() {
        events.add('some object');
        return false;
      });

      expect(identical(cache, _cacheRef.target), isTrue);
      expect(identical(cache[0], someObject), isTrue);
      expect(identical(cache[0], _someObjectRef.target), isTrue);

      cache = null;
      someObject = null;

      await parallelLoops([
        () {
          // ignore: unused_local_variable
          final bigChunkOfData = '0' * 1024 * 1024 * 50; // about 50mb of data.
          if (_cacheRef.target != null)
            return true;
          return _cacheRefDone();
        },
        () {
          // ignore: unused_local_variable
          final bigChunkOfData = '0' * 1024 * 1024 * 50; // about 50mb of data.
          if (_someObjectRef.target != null)
            return true;
          return _someObjectRefDone();
        },
      ]);

      expect(_cacheRef.target, isNull);
      expect(_someObjectRef.target, isNull);
      expect(
        events,
        unorderedEquals([
          'some object',
          'cache',
        ]),
      );
    });

    test('should support iteration', () async {
      final events = <String>[];

      WeakCache<int, _Int>? cache = WeakCache();
      final _cacheRef = WeakReference(cache);

      _Int? object = _Int(0);
      final _objectRef = WeakReference(object);

      cache[0] = object;
      for (var i = 1; i < 100; i++)
        cache[i] = _Int(i);

      // expect(identical(cache, _cacheRef.target), isTrue);

      final _cacheRefDone = expectAsync0<bool>(() {
        events.add('cache');
        return false;
      });

      final _objectRefDone = expectAsync0<bool>(() {
        events.add('object');
        return false;
      });

      var j = 0;
      // ignore: avoid_function_literals_in_foreach_calls
      cache.entries.forEach((kv) {
        expect(kv.key == kv.value.i, isTrue);
        j++;
      });

      // Some objects may be removed while testing
      expect(j, allOf(lessThanOrEqualTo(100), greaterThanOrEqualTo(1)));

      await Future<void>.delayed(const Duration(seconds: 1));
      cache = null;
      object = null;

      await parallelLoops([
        () {
          // ignore: unused_local_variable
          final bigChunkOfData = '0' * 1024 * 1024 * 50; // about 50mb of data.
          if (_cacheRef.target != null)
            return true;
          return _cacheRefDone();
        },
        () {
          // ignore: unused_local_variable
          final bigChunkOfData = '0' * 1024 * 1024 * 50; // about 50mb of data.
          if (_objectRef.target != null)
            return true;
          return _objectRefDone();
        },
      ]);
      expect(_cacheRef.target, isNull);
      expect(_objectRef.target, isNull);
      expect(
        events,
        unorderedEquals([
          'object',
          'cache',
        ]),
      );
    });

    // In previous version mutex state was frozen for new values,
    // meaning that when you add new value while iterating, this value
    // would be places unconditionally to remove queue, even is mutex is no
    // longer held.
    test('mutex state should update after iteration is done in finalizer', () async {
      final events = <String>[];

      WeakCache<int, Object>? cache = WeakCache<int, Object>();
      final _cacheRef = WeakReference(cache);

      // create objects
      Object? object1 = Object();
      final _object1Ref = WeakReference(object1);
      Object? object2 = Object();
      final _object2Ref = WeakReference(object2);

      // add first to cache
      cache[0] = object1;

      // lock mutex
      // ignore: unused_local_variable
      Iterable<Object>? values = cache.values;

      // add second object
      cache[1] = object2;

      final _cacheRefDone = expectAsync0<bool>(() {
        events.add('cache');
        return false;
      });

      final _object1RefDone = expectAsync0<bool>(() {
        events.add('object 1');
        return false;
      });

      final _object2RefDone = expectAsync0<bool>(() {
        events.add('object 2');
        return false;
      });

      expect(identical(cache, _cacheRef.target), isTrue);
      expect(identical(cache[0], object1), isTrue);
      expect(identical(cache[0], _object1Ref.target), isTrue);
      expect(identical(cache[1], object2), isTrue);
      expect(identical(cache[1], _object2Ref.target), isTrue);

      cache = null;
      object1 = null;

      // unlock mutex
      values = null;

      // wait for first object to GC
      await parallelLoops([
        () {
          // ignore: unused_local_variable
          final bigChunkOfData = '0' * 1024 * 1024 * 50; // about 50mb of data.
          if (_object1Ref.target != null)
            return true;
          return _object1RefDone();
        },
      ]);

      // remove 2nd object
      object2 = null;

      // wait for 2nd object and cache to GC
      await parallelLoops([
        () {
          // ignore: unused_local_variable
          final bigChunkOfData = '0' * 1024 * 1024 * 50; // about 50mb of data.
          if (_cacheRef.target != null)
            return true;
          return _cacheRefDone();
        },
        () {
          // ignore: unused_local_variable
          final bigChunkOfData = '0' * 1024 * 1024 * 50; // about 50mb of data.
          if (_object2Ref.target != null)
            return true;
          return _object2RefDone();
        },
      ]);

      expect(_cacheRef.target, isNull);
      expect(_object1Ref.target, isNull);
      expect(_object2Ref.target, isNull);
      expect(
        events,
        unorderedEquals([
          'object 1',
          'object 2',
          'cache',
        ]),
      );
    });

    test('softly support concurrent modification', () async {
      final events = <String>[];
      var modificationDone = false;

      WeakCache<int, _Int>? cache = WeakCache();
      final _cacheRef = WeakReference(cache);

      _Int? object = _Int(0);
      final _objectRef = WeakReference(object);

      final _cacheRefDone = expectAsync0<bool>(() {
        events.add('cache');
        return false;
      });

      final _objectRefDone = expectAsync0<bool>(() {
        events.add('object');
        return false;
      });

      final _modificationDone = expectAsync0<void>(max: -1, () {
        modificationDone = true;
      });

      cache[0] = object;
      for (var i = 1; i < 100; i++)
        cache[i] = _Int(i);

      object = null;

      await parallelLoops([
        () {
          for (final MapEntry(:key) in cache!.entries) {
            if (key > 50) {
              cache!.remove(key);
              _modificationDone();
            }
          }
          cache = null;
          return false;
        },
        () {
          // ignore: unused_local_variable
          final bigChunkOfData = '0' * 1024 * 1024 * 50; // about 50mb of data.
          if (_cacheRef.target != null)
            return true;
          return _cacheRefDone();
        },
        () {
          // ignore: unused_local_variable
          final bigChunkOfData = '0' * 1024 * 1024 * 50; // about 50mb of data.
          if (_objectRef.target != null)
            return true;
          return _objectRefDone();
        },
      ]);

      expect(_cacheRef.target, isNull);
      expect(_objectRef.target, isNull);
      expect(
        events,
        unorderedEquals([
          'object',
          'cache',
        ]),
      );
      expect(modificationDone, isTrue);
    });

  });
}
