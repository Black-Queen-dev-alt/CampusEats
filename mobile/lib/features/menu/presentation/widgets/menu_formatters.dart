String formatPrice(int priceInCents) =>
    '${(priceInCents ~/ 100)},${(priceInCents % 100).toString().padLeft(2, '0')} €';

String formatMenuDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
