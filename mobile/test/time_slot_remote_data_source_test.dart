import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_eats_mobile/core/network/api_client.dart';
import 'package:campus_eats_mobile/features/time_slots/data/time_slot_remote_data_source.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.body) : super(Dio());

  final Object body;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async => Response<T>(
    requestOptions: RequestOptions(path: path),
    data: body as T,
  );
}

void main() {
  test('rejects malformed slot payloads rather than reporting no slots', () {
    final source = TimeSlotRemoteDataSource(
      _FakeApiClient({'data': 'not-a-list'}),
    );

    expect(source.getTimeSlots('2026-11-26'), throwsFormatException);
  });
}
