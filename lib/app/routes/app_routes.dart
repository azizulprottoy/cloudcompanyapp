class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgotPassword';

  // Role shells (bottom navigation)
  static const clientShell = '/client';
  static const employeeShell = '/team';
  static const adminShell = '/admin';

  // Client
  static const packageDetails = '/packageDetails';
  static const checkout = '/checkout';
  static const payment = '/payment';
  static const clientOrderDetails = '/clientOrderDetails';
  static const blogDetails = '/blogDetails';
  static const editProfile = '/editProfile';

  // Team
  static const taskDetails = '/taskDetails';

  // Admin
  static const adminOrderDetails = '/adminOrderDetails';
  static const adminTaskDetails = '/adminTaskDetails';

  // Shared
  static const chat = '/chat';
  static const notifications = '/notifications';
  static const sendNotification = '/sendNotification';
}
