import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class InventoryReportSummary {
  final String startDate;
  final String endDate;
  final int totalRecords;
  final double totalPurchasedQty;
  final double totalGoodStock;
  final double totalRecoverable;
  final double totalFinalWaste;
  final double goodStockPercentage;
  final double recoverablePercentage;
  final double wastePercentage;

  const InventoryReportSummary({
    required this.startDate,
    required this.endDate,
    required this.totalRecords,
    required this.totalPurchasedQty,
    required this.totalGoodStock,
    required this.totalRecoverable,
    required this.totalFinalWaste,
    required this.goodStockPercentage,
    required this.recoverablePercentage,
    required this.wastePercentage,
  });

  factory InventoryReportSummary.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>;
    return InventoryReportSummary(
      startDate: period['start'] as String,
      endDate: period['end'] as String,
      totalRecords: _toInt(json['total_records']),
      totalPurchasedQty: _toDouble(json['total_purchased_qty']),
      totalGoodStock: _toDouble(json['total_good_stock']),
      totalRecoverable: _toDouble(json['total_recoverable']),
      totalFinalWaste: _toDouble(json['total_final_waste']),
      goodStockPercentage: _toDouble(json['good_stock_percentage']),
      recoverablePercentage: _toDouble(json['recoverable_percentage']),
      wastePercentage: _toDouble(json['waste_percentage']),
    );
  }
}

class ProductReportRow {
  final String productId;
  final String productName;
  final String unit;
  final double totalPurchased;
  final double totalGoodStock;
  final double totalRecoverable;
  final double totalWaste;
  final double wastePercentage;
  final int recordCount;

  const ProductReportRow({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.totalPurchased,
    required this.totalGoodStock,
    required this.totalRecoverable,
    required this.totalWaste,
    required this.wastePercentage,
    required this.recordCount,
  });

  factory ProductReportRow.fromJson(Map<String, dynamic> json) {
    return ProductReportRow(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      unit: (json['unit'] as String?) ?? 'kg',
      totalPurchased: _toDouble(json['total_purchased']),
      totalGoodStock: _toDouble(json['total_good_stock']),
      totalRecoverable: _toDouble(json['total_recoverable']),
      totalWaste: _toDouble(json['total_waste']),
      wastePercentage: _toDouble(json['waste_percentage']),
      recordCount: _toInt(json['record_count']),
    );
  }
}

class WasteReportRow {
  final String productId;
  final String productName;
  final String unit;
  final double totalPurchased;
  final double totalWaste;
  final double wastePercentage;
  final int recordCount;

  const WasteReportRow({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.totalPurchased,
    required this.totalWaste,
    required this.wastePercentage,
    required this.recordCount,
  });

  factory WasteReportRow.fromJson(Map<String, dynamic> json) {
    return WasteReportRow(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      unit: (json['unit'] as String?) ?? 'kg',
      totalPurchased: _toDouble(json['total_purchased']),
      totalWaste: _toDouble(json['total_waste']),
      wastePercentage: _toDouble(json['waste_percentage']),
      recordCount: _toInt(json['record_count']),
    );
  }
}

class RecoverableReportRow {
  final String productId;
  final String productName;
  final String unit;
  final double totalPurchased;
  final double totalRecoverable;
  final double recoverablePercentage;
  final int recordCount;

  const RecoverableReportRow({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.totalPurchased,
    required this.totalRecoverable,
    required this.recoverablePercentage,
    required this.recordCount,
  });

  factory RecoverableReportRow.fromJson(Map<String, dynamic> json) {
    return RecoverableReportRow(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      unit: (json['unit'] as String?) ?? 'kg',
      totalPurchased: _toDouble(json['total_purchased']),
      totalRecoverable: _toDouble(json['total_recoverable']),
      recoverablePercentage: _toDouble(json['recoverable_percentage']),
      recordCount: _toInt(json['record_count']),
    );
  }
}

class EmployeeReportRow {
  final String employeeId;
  final String employeeName;
  final int recordCount;
  final double totalPurchased;
  final double totalWaste;
  final double avgWastePercentage;

  const EmployeeReportRow({
    required this.employeeId,
    required this.employeeName,
    required this.recordCount,
    required this.totalPurchased,
    required this.totalWaste,
    required this.avgWastePercentage,
  });

  factory EmployeeReportRow.fromJson(Map<String, dynamic> json) {
    return EmployeeReportRow(
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      recordCount: _toInt(json['record_count']),
      totalPurchased: _toDouble(json['total_purchased']),
      totalWaste: _toDouble(json['total_waste']),
      avgWastePercentage: _toDouble(json['avg_waste_percentage']),
    );
  }
}

class InventoryReportsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<InventoryReportSummary> getSummary(String startDate, String endDate) async {
    final res = await _dio.get('/api/inventory-mgmt/reports/summary', queryParameters: {
      'start_date': startDate,
      'end_date': endDate,
    });
    return InventoryReportSummary.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<ProductReportRow>> getProductSummary(String startDate, String endDate) async {
    final res = await _dio.get('/api/inventory-mgmt/reports/products', queryParameters: {
      'start_date': startDate,
      'end_date': endDate,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    return (data['products'] as List)
        .map((e) => ProductReportRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WasteReportRow>> getWasteSummary(String startDate, String endDate) async {
    final res = await _dio.get('/api/inventory-mgmt/reports/waste', queryParameters: {
      'start_date': startDate,
      'end_date': endDate,
      'sort_by': 'waste_percentage',
      'sort_order': 'desc',
    });
    final data = res.data['data'] as Map<String, dynamic>;
    return (data['products'] as List)
        .map((e) => WasteReportRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecoverableReportRow>> getRecoverableSummary(String startDate, String endDate) async {
    final res = await _dio.get('/api/inventory-mgmt/reports/recoverable', queryParameters: {
      'start_date': startDate,
      'end_date': endDate,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    return (data['products'] as List)
        .map((e) => RecoverableReportRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<EmployeeReportRow>> getEmployeeSummary(String startDate, String endDate) async {
    final res = await _dio.get('/api/inventory-mgmt/reports/employees', queryParameters: {
      'start_date': startDate,
      'end_date': endDate,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    return (data['employees'] as List)
        .map((e) => EmployeeReportRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}
