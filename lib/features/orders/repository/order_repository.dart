import '../../../core/network/api_endpoints.dart';
import '../../../core/network/base_repository.dart';
import '../../../core/utils/formatters.dart';
import '../model/order_model.dart';

class OrderRepository extends BaseRepository {
  OrderRepository({super.dio});

  int _newestFirst(OrderModel a, OrderModel b) {
    final da = Formatters.parseDate(a.createdAt) ?? DateTime(2000);
    final db = Formatters.parseDate(b.createdAt) ?? DateTime(2000);
    return db.compareTo(da);
  }

  /// A client's package orders and custom requests (server hides ones the
  /// client already reviewed).
  Future<List<OrderModel>> clientOrders(String clientId) async {
    final res = await dio.get(ApiEndpoints.clientOrders(clientId));
    final regular = asList(res.data, key: 'regularOrders');
    final custom = asList(res.data, key: 'customOrders');
    return [...regular, ...custom].map(OrderModel.fromJson).toList()
      ..sort(_newestFirst);
  }

  Future<OrderModel> order(String id) async {
    final res = await dio.get(ApiEndpoints.order(id));
    return OrderModel.fromJson(asMap(res.data));
  }

  // ── Admin ───────────────────────────────────────────────────────────────────

  Future<List<OrderModel>> allOrders() async {
    final res = await dio.get(ApiEndpoints.allOrders);
    return asList(res.data).map(OrderModel.fromJson).toList()
      ..sort(_newestFirst);
  }

  /// pending | started | completed | rejected. The client gets a push on started/completed.
  Future<void> setStatus(String orderId, String status) async {
    await dio.post(ApiEndpoints.orderStatus(orderId), data: {'status': status});
  }

  /// Toggles one progress step's done flag. The server matches steps by [id]
  /// and leaves the rest of packageContents untouched.
  Future<void> setStepDone(
    String orderId,
    String stepId, {
    required bool isDone,
  }) async {
    await dio.put(
      ApiEndpoints.updatePackageStatus(orderId),
      data: {
        'packageContents': [
          {'id': stepId, 'isDone': isDone},
        ],
      },
    );
  }

  /// Marking paid emails the client and creates the project's tasks from its task flow.
  Future<int> setPaymentStatus(String orderId, {required bool paid}) async {
    final res = await dio.post(
      ApiEndpoints.orderPaymentStatus(orderId),
      data: {'pstatus': paid ? 'paid' : 'notpaid'},
    );
    final body = res.data;
    final created = body is Map ? body['createdTasks'] : null;
    return created is List
        ? created.length
        : (created is num ? created.toInt() : 0);
  }
}
