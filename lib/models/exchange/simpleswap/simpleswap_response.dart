enum SimpleSwapExceptionType { generic, serializeResponseError }

class SimpleSwapException implements Exception {
  String errorMessage;
  SimpleSwapExceptionType type;
  SimpleSwapException(this.errorMessage, this.type);

  @override
  String toString() {
    return errorMessage;
  }
}

class SimpleSwapResponse<T> {
  late final T? value;
  late final SimpleSwapException? exception;

  SimpleSwapResponse({this.value, this.exception});

  @override
  String toString() {
    return "{error: $exception, value: $value}";
  }
}
