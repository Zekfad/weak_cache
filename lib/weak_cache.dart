/// Weak cache that uses weak references for holding values.
/// 
/// It's useful in cases when you want to hold an object in cache while it's in
/// usage and remove it when it's no longer accessible.
library weak_cache;

export 'src/weak_cache.dart' show WeakCache;
