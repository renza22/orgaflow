import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_error.dart';

class ErrorMapper {
  static AppError map(Object error) {
    if (error is AppError) {
      return error;
    }

    if (error is AuthException) {
      return AppError(
        _mapAuthMessage(error.message),
        cause: error,
      );
    }

    if (error is PostgrestException) {
      return AppError(
        _mapPostgrestMessage(error),
        cause: error,
      );
    }

    return AppError(
      'Terjadi kesalahan tak terduga. Silakan coba lagi.',
      cause: error,
    );
  }

  static bool isMissingRpc(
    PostgrestException error,
    String functionName,
  ) {
    final message = error.message.toLowerCase();
    final details = (error.details ?? '').toString().toLowerCase();
    final hint = (error.hint ?? '').toString().toLowerCase();
    final functionKey = functionName.toLowerCase();

    return error.code == 'PGRST202' ||
        error.code == '42883' ||
        message.contains('function') && message.contains(functionKey) ||
        details.contains(functionKey) ||
        hint.contains(functionKey);
  }

  static String _mapAuthMessage(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('invalid login credentials')) {
      return 'Email atau password tidak valid.';
    }

    if (normalized.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek inbox Anda terlebih dahulu.';
    }

    if (normalized.contains('user already registered')) {
      return 'Email ini sudah terdaftar. Silakan login.';
    }

    if (normalized.contains('password should be at least')) {
      return 'Password terlalu pendek. Gunakan minimal 6 karakter.';
    }

    return message;
  }

  static String _mapPostgrestMessage(PostgrestException error) {
    final message = error.message.toLowerCase();

    if (message.contains('duplicate key value')) {
      return 'Data yang sama sudah ada.';
    }

    if (message.contains('invite code not found')) {
      return 'Kode organisasi tidak ditemukan atau organisasi sudah tidak aktif.';
    }

    if (message.contains('dependency must belong to the same project')) {
      return 'Dependency harus berasal dari project yang sama.';
    }

    if (message.contains('task_dependencies_not_self_chk')) {
      return 'Task tidak bisa bergantung pada dirinya sendiri.';
    }

    if (message.contains('row-level security')) {
      return 'Anda tidak memiliki izin untuk melakukan aksi ini.';
    }

    return error.message;
  }
}
