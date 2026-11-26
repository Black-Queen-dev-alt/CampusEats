import 'package:campus_eats_mobile/features/menu/domain/menu_repository.dart';

class GetMenu {
  const GetMenu(this.repository);

  final MenuRepository repository;

  Future<CachedMenuResult> getCached(String date) =>
      repository.getCachedMenu(date);

  Future<MenuResult> call(String date) => repository.getMenu(date);
}
