import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/menu/domain/daily_menu.dart';

typedef CachedMenuResult = ({
  DailyMenu? menu,
  DateTime? cachedAt,
  Failure? failure,
});
typedef MenuResult = ({DailyMenu? menu, Failure? failure});

abstract class MenuRepository {
  Future<CachedMenuResult> getCachedMenu(String date);
  Future<MenuResult> getMenu(String date);
}
