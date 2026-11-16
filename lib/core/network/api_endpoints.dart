/// Every backend path the app uses (cloudcompanyserver, no /api prefix).
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const clientLogin = '/clientlogin';
  static const employeeLogin = '/employeelogin';
  static const adminLogin = '/adminlogin';
  static const login = '/login';
  static const clientSignup = '/addclient';
  static const sendResetOtp = '/forgot-password/send-otp';
  static const verifyResetOtp = '/forgot-password/verify-otp';
  static const resetPassword = '/forgot-password/reset-password';

  // ── Public content ──────────────────────────────────────────────────────────
  static const homeCritical = '/home/critical';
  static const homeSecondary = '/home/secondary';
  static const packages = '/packages';
  static String packageDetails(String idOrSlug) => '/packdetails/$idOrSlug';
  static String packageWithCoupons(String id) => '/packages/$id';
  static const publicBlogs = '/publicblogs';
  static String blogDetails(String slug) => '/blogdetails/$slug';
  static String blogJsx(String slug) => '/blogjsx/$slug';

  // ── Client ──────────────────────────────────────────────────────────────────
  static String clientProfile(String id) => '/clientprofile/$id';
  static String updateClientProfile(String id) => '/addclientdp/$id';
  static String clientOrders(String id) => '/clientorders/$id';
  static String order(String id) => '/getorder/$id';
  static const buyPackage = '/buypackage';
  static const paymentMethods = '/payment';
  static String updateOrderPayment(String id) => '/updateorderpayment/$id';
  static String updatePackageStatus(String id) => '/updatePackageStatus/$id';

  // ── Employee ────────────────────────────────────────────────────────────────
  static String employeeProfile(String id) => '/employeeprofile/$id';
  static String updateEmployeeProfile(String id) => '/addemployeedp/$id';
  static String employeeTasks(String id) => '/employee/tasks/can-do/$id';
  static String employeeReady(String id) => '/employee/$id/ready';
  static String acceptTask(String id) => '/accepttask/$id';
  static String submitTask(String id) => '/comptask/$id';
  static String requestMoreTime(String id) => '/moretime/$id';
  static String taskFeedback(String id) => '/taskfeedback/$id';

  // ── Admin ───────────────────────────────────────────────────────────────────
  static const adminDashboard = '/admindashboard';
  static const allOrders = '/orders';
  static String orderStatus(String id) => '/orderstatus/$id';
  static String orderPaymentStatus(String id) => '/orderpaymentstatus/$id';
  static const allTasks = '/alltasks';
  static String verifyTask(String id) => '/verifytask/$id';

  // ── Chat ────────────────────────────────────────────────────────────────────
  static String orderChat(String orderId) => '/clichat/$orderId';
  static const sendOrderChat = '/addclichat';
  static const sendOrderChatFiles = '/addclichat/files';
  static String markOrderChatRead(String orderId) =>
      '/clichat/mark-read/$orderId';
  static String taskChat(String taskId) => '/empchat/$taskId';
  static const sendTaskChat = '/addempchat';
  static const sendTaskChatFiles = '/addempchat/files';
  static String markTaskChatRead(String taskId) => '/empchat/mark-read/$taskId';

  // ── Notifications ───────────────────────────────────────────────────────────
  static const notifications = '/notifications';
  static const publicNotifications = '/notifications/public';
  static const unreadNotifications = '/notifications/unread-count';
  static const readAllNotifications = '/notifications/read-all';
  static String readNotification(String id) => '/notifications/$id/read';
  static String notification(String id) => '/notifications/$id';
  static const adminNotifications = '/admin/notifications';
  static const deviceToken = '/push/device-token';
  static String task(String id) => '/task/$id';
}
