import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_eats_mobile/core/errors/error_mapper.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';

void main() {
  test('preserves the API conflict code for order conflict handling', () {
    final request = RequestOptions(path: '/orders');
    final failure = mapDioError(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 409,
          data: {
            'error': {'code': 'SLOT_FULL', 'message': 'Créneau complet'},
          },
        ),
      ),
    );

    expect(
      failure,
      isA<ConflictFailure>()
          .having((error) => error.code, 'code', 'SLOT_FULL')
          .having((error) => error.message, 'message', 'Créneau complet'),
    );
  });

  test('maps 422 details to field errors', () {
    final request = RequestOptions(path: '/orders');
    final failure = mapDioError(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 422,
          data: {
            'error': {
              'message': 'Données invalides',
              'details': [
                {'field': 'lines.0.quantity', 'message': 'Quantité invalide'},
              ],
            },
          },
        ),
      ),
    );

    expect(
      failure,
      isA<ValidationFailure>().having(
        (error) => error.fieldErrors['lines.0.quantity'],
        'quantity error',
        'Quantité invalide',
      ),
    );
  });
}
