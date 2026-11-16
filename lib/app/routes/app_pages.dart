import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/auth/session_service.dart';
import '../../features/auth/binding/auth_bindings.dart';
import '../../features/auth/view/forgot_password_page.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/auth/view/signup_page.dart';
import '../../features/blog/binding/blog_bindings.dart';
import '../../features/blog/view/blog_details_page.dart';
import '../../features/chat/binding/chat_binding.dart';
import '../../features/chat/view/chat_page.dart';
import '../../features/main/binding/shell_bindings.dart';
import '../../features/notifications/controller/send_notification_controller.dart';
import '../../features/notifications/view/notifications_page.dart';
import '../../features/notifications/view/send_notification_page.dart';
import '../../features/main/view/shell_pages.dart';
import '../../features/orders/binding/order_bindings.dart';
import '../../features/orders/view/order_details_page.dart';
import '../../features/packages/binding/package_bindings.dart';
import '../../features/packages/view/checkout_page.dart';
import '../../features/packages/view/package_details_page.dart';
import '../../features/packages/view/payment_page.dart';
import '../../features/profile/binding/profile_bindings.dart';
import '../../features/profile/view/edit_profile_page.dart';
import '../../features/splash/splash_page.dart';
import '../../features/tasks/binding/task_bindings.dart';
import '../../features/tasks/view/task_details_page.dart';
import 'app_routes.dart';

/// Sends signed-out users (or the wrong role) back to login.
class RoleGuard extends GetMiddleware {
  RoleGuard(this.roles);
  final Set<UserRole> roles;

  @override
  RouteSettings? redirect(String? route) {
    final role = SessionService.to.role.value;
    if (role == null || !roles.contains(role)) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

class AppPages {
  AppPages._();

  static final _client = [
    RoleGuard({UserRole.client}),
  ];
  static final _team = [
    RoleGuard({UserRole.employee}),
  ];
  static final _admin = [
    RoleGuard({UserRole.admin}),
  ];
  static final _signedIn = [RoleGuard(UserRole.values.toSet())];

  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupPage(),
      binding: SignupBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordPage(),
      binding: ForgotPasswordBinding(),
    ),

    // Shells
    GetPage(
      // Public — guests browse home/packages/blog here, same as the website.
      // Login is only enforced on checkout and the account/orders tabs.
      name: AppRoutes.clientShell,
      page: () => const ClientShellPage(),
      binding: ClientShellBinding(),
    ),
    GetPage(
      name: AppRoutes.employeeShell,
      page: () => const EmployeeShellPage(),
      binding: EmployeeShellBinding(),
      middlewares: _team,
    ),
    GetPage(
      name: AppRoutes.adminShell,
      page: () => const AdminShellPage(),
      binding: AdminShellBinding(),
      middlewares: _admin,
    ),

    // Client
    GetPage(
      // Public content — browsing a package doesn't need login, buying one does.
      name: AppRoutes.packageDetails,
      page: () => const PackageDetailsPage(),
      binding: PackageDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.checkout,
      page: () => const CheckoutPage(),
      binding: CheckoutBinding(),
      middlewares: _client,
    ),
    GetPage(
      name: AppRoutes.payment,
      page: () => const PaymentPage(),
      binding: PaymentBinding(),
      middlewares: _client,
    ),
    GetPage(
      name: AppRoutes.clientOrderDetails,
      page: () => const OrderDetailsPage(),
      binding: OrderDetailsBinding(),
      middlewares: _client,
    ),
    GetPage(
      // Public content, like the website's blog.
      name: AppRoutes.blogDetails,
      page: () => const BlogDetailsPage(),
      binding: BlogDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfilePage(),
      binding: EditProfileBinding(),
      middlewares: _signedIn,
    ),

    // Team
    GetPage(
      name: AppRoutes.taskDetails,
      page: () => const TaskDetailsPage(),
      binding: TaskDetailsBinding(),
      middlewares: _team,
    ),

    // Admin
    GetPage(
      name: AppRoutes.adminOrderDetails,
      page: () => const OrderDetailsPage(),
      binding: OrderDetailsBinding(),
      middlewares: _admin,
    ),
    GetPage(
      name: AppRoutes.adminTaskDetails,
      page: () => const TaskDetailsPage(),
      binding: TaskDetailsBinding(),
      middlewares: _admin,
    ),

    // Shared
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatPage(),
      binding: ChatBinding(),
      middlewares: _signedIn,
    ),
    GetPage(
      // Public: signed-out users see announcements here.
      name: AppRoutes.notifications,
      page: () => const NotificationsPage(),
    ),
    GetPage(
      name: AppRoutes.sendNotification,
      page: () => const SendNotificationPage(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => SendNotificationController()),
      ),
      middlewares: _admin,
    ),
  ];
}
