// Mapper des exceptions Dio vers les Failure définis
import 'package:dio/dio.dart';
import '../errors/failure.dart';

Failure mapDioError(DioError error) {
  switch (error.response?.statusCode) {
    case 401:
      return const UnauthorizedFailure();
    case 403:
      return const ForbiddenFailure();
    case 409:
      return const ConflictFailure();
    case 422:
      return const ValidationFailure();
    case 500:
    default:
      return const ServerFailure();
  }
}
