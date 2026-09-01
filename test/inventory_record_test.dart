import 'package:flutter_test/flutter_test.dart';
import 'package:one_stop_mandi_admin/features/inventory/data/models/inventory_record.dart';

void main() {
  test('parses all inventory notebook sections and totals', () {
    final record = InventoryRecord.fromJson({
      'id': 'record-1',
      'title': 'Daily notebook',
      'record_date': '2026-08-30',
      'status': 'draft',
      'purchasing_batch_count': 1,
      'purchasing_item_count': 1,
      'dispatch_item_count': 1,
      'damage_item_count': 1,
      'total_purchased_weight': '10',
      'total_purchasing_amount': '200',
      'total_labour_charge': '10',
      'total_transportation_charge': '5',
      'total_other_charges': '2',
      'purchasing_grand_total': '217',
      'total_dispatch_weight': '10',
      'total_dispatch_amount': '300',
      'total_damage_qty': '4',
      'total_recover_qty': '1',
      'total_waste_qty': '3',
      'purchasing_batches': [
        {
          'id': 'batch-1',
          'purchase_source': 'quicklo',
          'transportation_charge': '5',
          'other_charges': '2',
          'total_amount': '200',
          'total_labour_charge': '10',
          'grand_total': '217',
          'items': [
            {
              'id': 'purchase-1',
              'product_id': 'product-1',
              'product_name': 'Potato',
              'weight': '10',
              'rate': '20',
              'amount': '200',
              'labour_charge': '10',
            },
          ],
        },
      ],
      'dispatch_items': [
        {
          'id': 'dispatch-1',
          'product_id': 'product-1',
          'dispatch_to': 'Main warehouse',
          'pocket': 2,
          'weight': '10',
          'rate': '30',
          'amount': '300',
        },
      ],
      'damage_items': [
        {
          'id': 'damage-1',
          'product_id': 'product-1',
          'damage_by': 'om',
          'damage_qty': '4',
          'recover_qty': '1',
          'waste_qty': '3',
        },
      ],
    });

    expect(record.purchasingBatches.single.grandTotal, 217);
    expect(record.dispatchItems.single.dispatchToLabel, 'Main warehouse');
    expect(record.damageItems.single.wasteQty, 3);
    expect(record.totalRowCount, 3);
    expect(record.totalPurchasedWeight, 10);
    expect(record.totalDispatchWeight, 10);
    expect(record.purchasingGrandTotal, 217);
  });
}
