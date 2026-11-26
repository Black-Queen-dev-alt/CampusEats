abstract class MenuEvent {
  const MenuEvent();
}

class MenuRequested extends MenuEvent {
  const MenuRequested(this.date);
  final String date;
}

class MenuRefreshRequested extends MenuEvent {
  const MenuRefreshRequested(this.date);
  final String date;
}

class DishFilterChanged extends MenuEvent {
  const DishFilterChanged(this.category);
  final String? category;
}
