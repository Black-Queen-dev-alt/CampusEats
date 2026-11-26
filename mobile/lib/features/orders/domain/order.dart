import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  const OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final int unitPrice;

  int get subtotal => quantity * unitPrice;

  @override
  List<Object?> get props => [name, quantity, unitPrice];
}

enum OrderStatus {
  received,
  preparing,
  ready,
  collected,
  cancelled,
  unknown;

  static OrderStatus fromApi(String? value) {
    final normalized = value?.toLowerCase().replaceAll('-', '_');
    if (normalized == null) return unknown;
    if (normalized.contains('prepar')) return preparing;
    if (normalized.contains('ready') || normalized.contains('pret')) {
      return ready;
    }
    if (normalized.contains('collect') ||
        normalized.contains('retir') ||
        normalized.contains('withdraw')) {
      return collected;
    }
    if (normalized.contains('cancel') || normalized.contains('annul')) {
      return cancelled;
    }
    if (normalized.contains('received') ||
        normalized.contains('recu') ||
        normalized.contains('pending')) {
      return received;
    }
    return unknown;
  }

  String get label => switch (this) {
    received => 'Reçue',
    preparing => 'En préparation',
    ready => 'Prête',
    collected => 'Retirée',
    cancelled => 'Annulée',
    unknown => 'Statut indisponible',
  };

  bool get cancellable => this == received;
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.number,
    required this.timeSlotId,
    required this.timeSlotLabel,
    required this.items,
    required this.total,
    required this.status,
    this.cancellationDeadline,
    this.qrValue,
  });

  final String id;
  final String number;
  final String timeSlotId;
  final String timeSlotLabel;
  final List<OrderItem> items;
  final int total;
  final OrderStatus status;
  final DateTime? cancellationDeadline;
  final String? qrValue;

  Order copyWith({OrderStatus? status, String? timeSlotLabel}) => Order(
    id: id,
    number: number,
    timeSlotId: timeSlotId,
    timeSlotLabel: timeSlotLabel ?? this.timeSlotLabel,
    items: items,
    total: total,
    status: status ?? this.status,
    cancellationDeadline: cancellationDeadline,
    qrValue: qrValue,
  );

  @override
  List<Object?> get props => [
    id,
    number,
    timeSlotId,
    timeSlotLabel,
    items,
    total,
    status,
    cancellationDeadline,
    qrValue,
  ];
}
