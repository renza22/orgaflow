import 'package:flutter_test/flutter_test.dart';
import 'package:orgaflow/core/errors/app_error.dart';
import 'package:orgaflow/core/result/result.dart';

void main() {
  test('Result success stores data', () {
    const result = Result<int>.success(42);

    expect(result.isSuccess, isTrue);
    expect(result.data, 42);
    expect(result.error, isNull);
  });

  test('Result failure stores error', () {
    const error = AppError('failure');
    const result = Result<void>.failure(error);

    expect(result.isFailure, isTrue);
    expect(result.error?.message, 'failure');
  });
}
