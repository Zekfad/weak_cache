import 'ffi_types.dart' as ffi;


bool _isAssignable<Target, Actual>() => <Actual>[] is List<Target>;

bool expandoCompatible<T>() => !(
  _isAssignable<num, T>() ||
  _isAssignable<String, T>() ||
  _isAssignable<bool, T>() ||
  _isAssignable<Record, T>() ||
  _isAssignable<ffi.Pointer, T>() ||
  _isAssignable<ffi.Struct, T>() ||
  _isAssignable<ffi.Union, T>()
);
