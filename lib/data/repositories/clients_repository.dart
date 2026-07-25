import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../models/client.dart';
import '../models/client_billing.dart';

class ClientsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<({List<ClientSummary> clients, int total, int totalPages})> listClients({
    String? search,
    String? setupApprovalStatus,
    String? accountStatus,
    bool? hasOutstanding,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (setupApprovalStatus != null) 'setup_approval_status': setupApprovalStatus,
      if (accountStatus != null) 'account_status': accountStatus,
      if (hasOutstanding == true) 'has_outstanding': true,
    };
    final res = await _dio.get('/api/admin/clients', queryParameters: params);
    final body = res.data as Map<String, dynamic>;
    final dataList = body['data'] as List<dynamic>;
    final pagination = body['pagination'] as Map<String, dynamic>;
    return (
      clients: dataList
          .map((e) => ClientSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination['total'] as int? ?? 0,
      totalPages: pagination['total_pages'] as int? ?? 1,
    );
  }

  Future<ClientDetail> getClient(String id) async {
    final res = await _dio.get('/api/admin/users/$id');
    return ClientDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ClientDetail> createClient({
    required String phone,
    String? name,
    String? businessName,
    String? ownerName,
    String? address,
    String? pincode,
    String? outletType,
    String? gstNumber,
    String? fssaiNumber,
  }) async {
    try {
      final res = await _dio.post('/api/admin/clients', data: {
        'phone': phone,
        if (name != null && name.isNotEmpty) 'name': name,
        if (businessName != null && businessName.isNotEmpty)
          'business_name': businessName,
        if (ownerName != null && ownerName.isNotEmpty) 'owner_name': ownerName,
        if (address != null && address.isNotEmpty) 'address': address,
        if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
        if (outletType != null && outletType.isNotEmpty)
          'outlet_type': outletType,
        if (gstNumber != null && gstNumber.isNotEmpty) 'gst_number': gstNumber,
        if (fssaiNumber != null && fssaiNumber.isNotEmpty)
          'fssai_number': fssaiNumber,
      });
      // create returns a subset; fetch full profile
      final id = res.data['data']['id'] as String;
      return getClient(id);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to create client');
    }
  }

  Future<ClientDetail> updateClient(
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _dio.patch('/api/admin/clients/$id', data: fields);
      return getClient(id);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update client');
    }
  }

  Future<void> setSetupApproval(
    String id, {
    required String status,
    String? note,
  }) async {
    try {
      await _dio.patch('/api/admin/clients/$id/setup-approval', data: {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      });
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update setup approval');
    }
  }

  Future<void> setBlocked(
    String id, {
    required bool blocked,
    String? reason,
  }) async {
    try {
      await _dio.patch('/api/admin/users/$id/block', data: {
        'blocked': blocked,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update block status');
    }
  }

  Future<ClientBillingSummary> getBillingSummary(String clientId) async {
    final res = await _dio.get('/api/admin/clients/$clientId/billing/summary');
    return ClientBillingSummary.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<ClientBillingOrder>> listBillingOrders(
    String clientId, {
    String status = 'all',
  }) async {
    final res = await _dio.get(
      '/api/admin/clients/$clientId/billing/orders',
      queryParameters: {'status': status, 'limit': 50},
    );
    final dataList = res.data['data'] as List<dynamic>;
    return dataList
        .map((e) => ClientBillingOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markOrderPaid(
    String clientId,
    String orderId, {
    String? reference,
  }) async {
    try {
      await _dio.patch(
        '/api/admin/clients/$clientId/orders/$orderId/payment',
        data: {if (reference != null && reference.isNotEmpty) 'reference': reference},
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to mark order paid');
    }
  }

  ApiException _mapError(DioException e, String fallback) {
    if (e.error is ApiException) return e.error as ApiException;
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return ApiException(data['message'] as String, statusCode: e.response?.statusCode);
    }
    return ApiException(fallback, statusCode: e.response?.statusCode);
  }
}
