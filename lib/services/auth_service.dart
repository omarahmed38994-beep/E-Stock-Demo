import '../core/api_client.dart';
import '../core/storage_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<AppUser> login(String email, String password) async {
    final data = await _api.post('/auth/login', data: {'email': email, 'password': password});
    final token = data['access_token'] as String;
    final user = AppUser.fromJson(data['user']);
    await StorageService.saveToken(token);
    await StorageService.saveUser(user.toJson());
    return user;
  }

  Future<AppUser?> restoreSession() async {
    final token = await StorageService.getToken();
    if (token == null) return null;
    final cached = await StorageService.getUser();
    if (cached != null) {
      // Return cached user instantly; a fresh /auth/me check could be added
      // here for stricter validation, but for the demo this keeps launch fast.
      return AppUser.fromJson(cached);
    }
    return null;
  }

  Future<void> logout() async {
    await StorageService.clearSession();
  }
}
