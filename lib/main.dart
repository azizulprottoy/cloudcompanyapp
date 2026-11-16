import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'core/auth/session_service.dart';
import 'core/storage/local_storage_service.dart';
import 'core/storage/secure_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Same start-up order as Kaj Ache: storage first, then services that read it.
  await Get.putAsync(() => LocalStorageService().init());
  await Get.putAsync(() => SecureStorageService().init());
  await Get.putAsync(() => SessionService().init());
  runApp(const CloudCompanyApp());
}
