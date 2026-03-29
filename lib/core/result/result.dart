import '../errors/app_error.dart';

class Result<T> {
  const Result._({
    this.data,
    this.error,
  });

  const Result.success(this.data) : error = null;

  const Result.failure(this.error) : data = null;

  final T? data;
  final AppError? error;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  static Result<T> successValue<T>(T data) => Result<T>._(data: data);

  static Result<T> failureValue<T>(AppError error) => Result<T>._(error: error);
}
