import 'package:dio/dio.dart';

import 'api_client.dart';

/// Shared helpers for repositories. The backend has no consistent response
/// envelope (raw arrays, raw documents, `{data: ...}`, `{package: ...}`), so
/// these unwrap the common shapes in one place.
abstract class BaseRepository {
  BaseRepository({Dio? dio}) : dio = dio ?? ApiClient.instance;

  final Dio dio;

  /// Returns the list at [key] (or the body itself when it is a list).
  List<Map<String, dynamic>> asList(dynamic body, {String? key}) {
    dynamic data = body;
    if (data is Map && key != null && data[key] is List) data = data[key];
    if (data is Map && data['data'] is List) data = data['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Returns the map at [key] (or the body itself when it is a map).
  Map<String, dynamic> asMap(dynamic body, {String? key}) {
    dynamic data = body;
    if (data is Map && key != null && data[key] is Map) data = data[key];
    if (data is Map && data['data'] is Map) data = data['data'];
    if (data is! Map) throw Exception('Unexpected response from the server.');
    return Map<String, dynamic>.from(data);
  }

  /// Mongo write results look like {acknowledged, modifiedCount, insertedId}.
  bool writeOk(dynamic body) {
    if (body is! Map) return true;
    if (body['success'] == false) return false;
    if (body['acknowledged'] == false) return false;
    return true;
  }
}

/// Mongo ObjectIds may arrive as "abc…" or {"$oid": "abc…"}.
String idOf(dynamic value) {
  if (value is Map && value[r'$oid'] != null) return value[r'$oid'].toString();
  return value?.toString() ?? '';
}
