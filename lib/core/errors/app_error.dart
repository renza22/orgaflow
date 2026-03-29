class AppError {
  const AppError(
    this.message, {
    this.cause,
  });

  final String message;
  final Object? cause;
}
