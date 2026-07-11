import 'package:rugby_jam_mobile/features/auth/data/auth_models.dart';

String fallbackUserValue(String? value, String fallback) {
  if (value == null || value.trim().isEmpty) {
    return fallback;
  }

  return value;
}

String formatUserRole(AuthRole? role) {
  return switch (role) {
    AuthRole.admin => 'ADMIN',
    AuthRole.user => 'USER',
    null => 'Non disponible',
  };
}

String formatUserDate(DateTime? value) {
  if (value == null) {
    return 'Non disponible';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();

  return '$day/$month/$year';
}

String formatUserDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}
