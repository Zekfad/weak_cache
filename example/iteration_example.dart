import 'package:weak_cache/src/debug.dart' show kDebug;
import 'package:weak_cache/weak_cache.dart';


Future<void> main(List<String> args) async {
  kDebug = true;
  WeakCache<int, Object>? cache = WeakCache();
  final objectRef = WeakReference(cache[0] = Object());
  for (var i = 1; i < 100; i++)
    cache[i] = Object();

  final cacheRef = WeakReference(cache);

  Future.doWhile(() async {
    print('Feed memory to force GC');
    // ignore: unused_local_variable
    final bigChunkOfData = '0' * 1024 * 1024 * 25; // about 52mb of data.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    return cacheRef.target != null || objectRef.target != null;
  }).then(
    (value) {
      print('Cache and object were garbage collected');
    },
  ).ignore();

  // Add delay if you want to see that objects were deleted before iteration
  // could hold them.
  // await Future<void>.delayed(const Duration(seconds: 1));

  for (final MapEntry(:key, :value) in cache.entries) {
    print('$key = $value');
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }

  await Future<void>.delayed(const Duration(seconds: 1));
  cache = null;
}
