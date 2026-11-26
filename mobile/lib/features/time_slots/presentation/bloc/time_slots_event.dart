abstract class TimeSlotsEvent {
  const TimeSlotsEvent();
}

class TimeSlotsRequested extends TimeSlotsEvent {
  const TimeSlotsRequested(this.date);
  final String date;
}

class SlotRefreshRequested extends TimeSlotsEvent {
  const SlotRefreshRequested(this.date);
  final String date;
}
