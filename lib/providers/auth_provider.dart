import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final bool loading;

  AuthState({required this.status, this.user, this.error, this.loading = false});

  AuthState copyWith({AuthStatus? status, AppUser? user, String? error, bool? loading}) => AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
        loading: loading ?? false,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(AuthState(status: AuthStatus.unknown)) {
    _restore();
  }

  Future<void> _restore() async {
    final user = await _authService.restoreSession();
    if (user != null) {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await _authService.login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.toString().replaceFirst('ApiException: ', ''));
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
