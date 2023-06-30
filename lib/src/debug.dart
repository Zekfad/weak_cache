/// Debug mode that controls [debugPrint] behavior.
bool kDebug = false;

/// Debug print function:
/// * No-op is [kDebug] is `false`.
/// * Direct call to [print] otherwise.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
final void Function(Object? object) debugPrint = !kDebug
  ? (object) {}
  : print; 
