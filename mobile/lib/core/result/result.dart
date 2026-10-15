/// Result type for functional error handling across Clean Architecture layers.
/// Prevents unhandled exceptions from leaking into presentation/Bloc.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  T? get dataOrNull => switch (this) {
        Success<T>(data: final d) => d,
        FailureResult<T>() => null,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, String? code) failure,
  }) {
    return switch (this) {
      Success<T>(data: final d) => success(d),
      FailureResult<T>(message: final m, code: final c) => failure(m, c),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class FailureResult<T> extends Result<T> {
  final String message;
  final String? code;
  final int? statusCode;

  const FailureResult({
    required this.message,
    this.code,
    this.statusCode,
  });
}
