import 'package:flutter_test/flutter_test.dart';
import 'package:adminpanel/features/offers/domain/entities/offer_filters.dart';

void main() {
  test('OfferFilters reports active filters and clears values', () {
    const filters = OfferFilters(cityId: 'lahore', isPublished: true);

    expect(filters.hasActiveFilters, isTrue);

    final cleared = filters.copyWith(clearCity: true, clearPublished: true);

    expect(cleared.cityId, isNull);
    expect(cleared.isPublished, isNull);
    expect(cleared.hasActiveFilters, isFalse);
  });
}
