/// Weak cache that uses weak references for holding values.
/// 
/// You can use it to hold an object in cache while it's in usage, cache will
/// automatically remove it when it's no longer referenced.
library weak_cache;

export 'src/weak_cache.dart' show WeakCache;
