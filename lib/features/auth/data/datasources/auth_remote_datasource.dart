import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_config.dart';
import '../../domain/models/register_input.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> requestPasswordReset({
    required String email,
  }) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<AuthResponse> signUp(RegisterInput input) {
    return _client.auth.signUp(
      email: input.email,
      password: input.password,
      data: {
        'full_name': input.fullName,
      },
    );
  }
}
