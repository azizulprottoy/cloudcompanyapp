import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/auth/session_service.dart';
import '../../../core/error/api_error.dart';
import '../../../core/utils/app_services.dart';
import '../../chat/model/chat_models.dart';
import '../model/order_model.dart';
import '../repository/order_repository.dart';

/// Client "My Projects" tab.
class ClientOrdersController extends GetxController {
  ClientOrdersController({OrderRepository? repository})
    : _repository = repository ?? OrderRepository();

  final OrderRepository _repository;

  final orders = <OrderModel>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      orders.assignAll(
        await _repository.clientOrders(SessionService.to.current.id),
      );
    } catch (e) {
      error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }
}

/// One project, opened by a client or an admin (the page adapts to the role).
class OrderDetailsController extends GetxController {
  OrderDetailsController({OrderRepository? repository})
    : _repository = repository ?? OrderRepository();

  final OrderRepository _repository;

  final order = Rxn<OrderModel>();
  final isLoading = false.obs;
  final isSaving = false.obs;
  final error = ''.obs;

  bool get isAdmin => SessionService.to.role.value == UserRole.admin;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is OrderModel) order.value = arg;
    load(arg is OrderModel ? arg.id : arg.toString());
  }

  Future<void> load([String? id]) async {
    final orderId = id ?? order.value?.id;
    if (orderId == null || orderId.isEmpty) return;
    // Custom requests have no /getorder endpoint; keep the list copy.
    if (order.value?.isCustom == true) return;
    isLoading.value = true;
    error.value = '';
    try {
      order.value = await _repository.order(orderId);
    } catch (e) {
      if (order.value == null) error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void openChat() {
    final o = order.value;
    if (o == null) return;
    final me = SessionService.to.current;
    Get.toNamed(
      AppRoutes.chat,
      arguments: ChatRoom(
        kind: ChatKind.order,
        roomId: o.id,
        title: isAdmin ? '${o.buyerName} · ${o.displayTitle}' : o.displayTitle,
        mySender: isAdmin ? 'manager' : 'client',
        participantId: isAdmin ? o.buyerId : me.id,
        participantName: isAdmin ? o.buyerName : me.name,
        myUserId: me.id,
      ),
    );
  }

  void pay() {
    final o = order.value;
    if (o == null) return;
    Get.toNamed(
      AppRoutes.payment,
      arguments: {'orderId': o.id, 'amount': o.price, 'title': o.displayTitle},
    )?.then((_) => load());
  }

  // ── Admin actions ───────────────────────────────────────────────────────────

  Future<void> setStatus(String status) async {
    final o = order.value;
    if (o == null || o.status == status) return;
    isSaving.value = true;
    try {
      await _repository.setStatus(o.id, status);
      await load();
      AppServices.showSuccess(
        'Status changed to ${StatusStyle.order(status).label}.',
      );
    } catch (e) {
      AppServices.showApiError(e);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleStep(OrderStep step) async {
    final o = order.value;
    if (o == null || isSaving.value) return;
    isSaving.value = true;
    try {
      await _repository.setStepDone(o.id, step.id, isDone: !step.isDone);
      await load();
    } catch (e) {
      AppServices.showApiError(e);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> togglePaid() async {
    final o = order.value;
    if (o == null) return;
    final markPaid = !o.isPaid;
    final ok = await AppServices.confirm(
      title: markPaid ? 'Mark as paid?' : 'Mark as unpaid?',
      message: markPaid
          ? 'The client gets a confirmation email and the project tasks are created for the team.'
          : 'The order goes back to unpaid.',
      confirmText: markPaid ? 'Mark paid' : 'Mark unpaid',
    );
    if (!ok) return;
    isSaving.value = true;
    try {
      final tasks = await _repository.setPaymentStatus(o.id, paid: markPaid);
      await load();
      AppServices.showSuccess(
        markPaid
            ? 'Marked as paid${tasks > 0 ? ' · $tasks tasks created' : ''}.'
            : 'Marked as unpaid.',
      );
    } catch (e) {
      AppServices.showApiError(e);
    } finally {
      isSaving.value = false;
    }
  }
}

/// Admin "Orders" tab.
class AdminOrdersController extends GetxController {
  AdminOrdersController({OrderRepository? repository})
    : _repository = repository ?? OrderRepository();

  final OrderRepository _repository;

  static const filters = ['all', 'pending', 'started', 'completed', 'unpaid'];

  final orders = <OrderModel>[].obs;
  final filter = 'all'.obs;
  final query = ''.obs;
  final isLoading = false.obs;
  final error = ''.obs;

  List<OrderModel> get visible {
    final q = query.value.trim().toLowerCase();
    return orders.where((o) {
      final f = filter.value;
      if (f == 'unpaid' && o.isPaid) return false;
      if (f != 'all' && f != 'unpaid' && o.status != f) return false;
      if (q.isEmpty) return true;
      return o.displayTitle.toLowerCase().contains(q) ||
          o.buyerName.toLowerCase().contains(q) ||
          o.buyerEmail.toLowerCase().contains(q) ||
          o.packageName.toLowerCase().contains(q);
    }).toList();
  }

  int count(String f) => switch (f) {
    'all' => orders.length,
    'unpaid' => orders.where((o) => !o.isPaid).length,
    _ => orders.where((o) => o.status == f).length,
  };

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      orders.assignAll(await _repository.allOrders());
    } catch (e) {
      error.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }
}
