import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class InventoryDashboardData {
  final Map<String, String> period;
  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> topPurchasedProducts;
  final List<Map<String, dynamic>> highestWasteProducts;
  final List<Map<String, dynamic>> highestRecoverableProducts;
  final List<Map<String, dynamic>> dailyTrend;

  const InventoryDashboardData({
    required this.period,
    required this.metrics,
    required this.topPurchasedProducts,
    required this.highestWasteProducts,
    required this.highestRecoverableProducts,
    required this.dailyTrend,
  });

  factory InventoryDashboardData.fromJson(Map<String, dynamic> json) {
    return InventoryDashboardData(
      period: Map<String, String>.from(json['period'] as Map),
      metrics: json['metrics'] as Map<String, dynamic>,
      topPurchasedProducts: (json['top_purchased_products'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      highestWasteProducts: (json['highest_waste_products'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      highestRecoverableProducts: (json['highest_recoverable_products'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      dailyTrend: (json['daily_trend'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}

class InventoryDashboardRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<InventoryDashboardData> getDashboard({
    String period = 'this_month',
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, dynamic>{
      'period': period,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };
    final res = await _dio.get('/api/inventory-mgmt/dashboard', queryParameters: params);
    return InventoryDashboardData.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
