import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/clients_repository.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/uploaded_orders_repository.dart';
import '../../data/repositories/admin_users_repository.dart';
import '../../data/repositories/pricing_repository.dart';
import '../../data/repositories/device_tokens_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) => OrdersRepository());
final clientsRepositoryProvider = Provider<ClientsRepository>((ref) => ClientsRepository());
final productsRepositoryProvider = Provider<ProductsRepository>((ref) => ProductsRepository());
final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) => CategoriesRepository());
final uploadedOrdersRepositoryProvider =
    Provider<UploadedOrdersRepository>((ref) => UploadedOrdersRepository());
final adminUsersRepositoryProvider =
    Provider<AdminUsersRepository>((ref) => AdminUsersRepository());
final pricingRepositoryProvider = Provider<PricingRepository>((ref) => PricingRepository());
final deviceTokensRepositoryProvider = Provider<DeviceTokensRepository>((ref) => DeviceTokensRepository());
