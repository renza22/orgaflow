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

  Future<String?> resolveEmailByNim(String nim) async {
    final response = await _client.rpc(
      'resolve_login_email_by_nim',
      params: {
        'p_nim': nim,
      },
    );

    final email = (response as String?)?.trim();
    if (email == null || email.isEmpty) {
      return null;
    }

    return email;
  }

  Future<void> requestPasswordReset({
    required String email,
  }) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
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
