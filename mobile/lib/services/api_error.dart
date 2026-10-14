import 'api_client.dart';

/// Pesan untuk ditampilkan dari error API: pesan field pertama (422),
/// lalu pesan server; [fallback] untuk error jaringan atau 5xx.
String apiErrorMessage(Object error, {required String fallback}) {
  if (error is! ApiException) return fallback;
  final field = error.errors?.values.firstOrNull;
  if (field is List && field.isNotEmpty) return '${field.first}';
  return error.statusCode >= 500 ? fallback : error.message;
}
