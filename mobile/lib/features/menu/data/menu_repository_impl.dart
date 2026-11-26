import 'package:dio/dio.dart';
import 'package:campus_eats_mobile/core/errors/error_mapper.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/menu/data/menu_local_data_source.dart';
import 'package:campus_eats_mobile/features/menu/data/menu_remote_data_source.dart';
import 'package:campus_eats_mobile/features/menu/domain/menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  const MenuRepositoryImpl({required this.remote, required this.local});

  final MenuRemoteDataSource remote;
  final MenuLocalDataSource local;

  @override
  Future<CachedMenuResult> getCachedMenu(String date) async {
    try {
      final result = await local.getMenu(date);
      return (
        menu: result.menu?.toDomain(),
        cachedAt: result.cachedAt,
        failure: null,
      );
    } on FormatException catch (error) {
      return (
        menu: null,
        cachedAt: null,
        failure: ServerFailure(error.message),
      );
    }
  }

  @override
  Future<MenuResult> getMenu(String date) async {
    try {
      final dto = await remote.getMenu(date);
      final saved = await local.saveMenu(date, dto);
      if (!saved) {
        return (
          menu: dto.toDomain(),
          failure: const ServerFailure('Impossible de mettre le menu en cache'),
        );
      }
      return (menu: dto.toDomain(), failure: null);
    } on DioException catch (error) {
      final failure = mapDioError(error);
      if (failure is NotFoundFailure) {
        await local.removeMenu(date);
        return (menu: null, failure: null);
      }
      return (menu: null, failure: failure);
    } on FormatException catch (error) {
      return (menu: null, failure: ServerFailure(error.message));
    }
  }
}
