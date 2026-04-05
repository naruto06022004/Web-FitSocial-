import '../api/api_client.dart';
import '../models/fitnet_user.dart';
import '../storage/token_storage.dart';

class AuthRepository {
  AuthRepository({required ApiClient api, required TokenStorage tokenStorage})
      : _api = api,
        _tokenStorage = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  Future<FitnetUser> login({required String email, required String password}) async {
    final json = await _api.postJson(
      '/api/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );
    final token = json['token']?.toString();
    final userJson = json['user'];
    if (token == null || token.isEmpty) {
      throw const FormatException('Missing token in response');
    }
    if (userJson is! Map) {
      throw const FormatException('Missing user in response');
    }
    await _tokenStorage.writeToken(token);
    return FitnetUser.fromJson(userJson.cast<String, dynamic>());
  }

  Future<FitnetUser> register({
    required String email,
    required String password,
  }) async {
    final json = await _api.postJson(
      '/api/auth/register',
      {'email': email, 'password': password},
      auth: false,
    );
    final token = json['token']?.toString();
    final userJson = json['user'];
    if (token == null || token.isEmpty) {
      throw const FormatException('Missing token in response');
    }
    if (userJson is! Map) {
      throw const FormatException('Missing user in response');
    }
    await _tokenStorage.writeToken(token);
    return FitnetUser.fromJson(userJson.cast<String, dynamic>());
  }

  Future<FitnetUser> me() async {
    final json = await _api.getJson('/api/me');
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Missing data in /api/me response');
    }
    return FitnetUser.fromJson(data.cast<String, dynamic>());
  }

  Future<void> logout() async {
    try {
      await _api.postJson('/api/auth/logout', const <String, dynamic>{});
    } catch (_) {
      // ignore network errors; always clear local token
    }
    await _tokenStorage.deleteToken();
  }
}

