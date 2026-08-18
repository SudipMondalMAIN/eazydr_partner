import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_exception.dart';
import '../core_providers.dart';
import '../models/user.dart';

enum SessionStatus { unknown, loggedIn, loggedOut }

class AuthState {
  final SessionStatus status;
  final AppUser? user;
  final String? error;
  const AuthState({required this.status, this.user, this.error});

  AuthState copyWith({SessionStatus? status, AppUser? user, String? error}) =>
      AuthState(status: status ?? this.status, user: user ?? this.user, error: error);
}

/// Same login flow as the patient app, but this app is merchant-only:
/// any account that authenticates successfully but isn't role == "merchant"
/// is immediately logged back out with a clear error, rather than letting
/// a patient account land inside the partner dashboard.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final storage = ref.read(localStorageProvider);
    if (storage.accessToken != null) {
      Future.microtask(fetchCurrentUser);
      return const AuthState(status: SessionStatus.loggedIn);
    }
    return const AuthState(status: SessionStatus.loggedOut);
  }

  Future<void> fetchCurrentUser() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/api/v1/auth/me');
      final user = AppUser.fromJson(res.data);
      if (user.role != 'merchant') {
        await logout(error: 'This app is for partner accounts only.');
        return;
      }
      state = AuthState(status: SessionStatus.loggedIn, user: user);
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await logout();
      } else if (state.status == SessionStatus.unknown) {
        state = const AuthState(status: SessionStatus.loggedIn);
      }
    } catch (_) {
      if (state.status == SessionStatus.unknown) {
        state = const AuthState(status: SessionStatus.loggedIn);
      }
    }
  }

  /// Step 1: register the account. Backend emails an OTP automatically,
  /// which must be verified via [verifySignupOtp] before login works.
  /// Registered with role "merchant" — this app is partner-only.
  Future<void> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/auth/register', data: {
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'password': password,
      'role': 'merchant',
    });
  }

  Future<void> verifySignupOtp(
      {required String email, required String otp}) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/auth/otp/verify-signup',
        data: {'email': email, 'otp': otp});
    await _saveTokensAndLoadUser(res.data);
  }

  Future<void> loginWithPassword(
      {required String identifier, required String password}) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/auth/login',
        data: {'identifier': identifier, 'password': password});
    await _saveTokensAndLoadUser(res.data);
  }

  Future<void> forgotPassword({required String email}) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/auth/forgot-password', data: {'identifier': email});
  }

  Future<void> resetPassword(
      {required String email,
      required String otp,
      required String newPassword}) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/auth/reset-password',
        data: {'identifier': email, 'otp': otp, 'new_password': newPassword});
  }

  Future<void> _saveTokensAndLoadUser(Map<String, dynamic> tokenJson) async {
    final storage = ref.read(localStorageProvider);
    await storage.saveTokens(
        access: tokenJson['access_token'], refresh: tokenJson['refresh_token']);
    await fetchCurrentUser();
    await _registerPendingPushTokenIfAny();
  }

  String? _pendingPushToken;

  Future<void> registerPushToken(String token) async {
    _pendingPushToken = token;
    await _registerPendingPushTokenIfAny();
  }

  Future<void> _registerPendingPushTokenIfAny() async {
    final token = _pendingPushToken;
    if (token == null || state.status != SessionStatus.loggedIn) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/api/v1/auth/me/push-token',
          data: {'device_push_token': token});
    } catch (_) {
      // best-effort
    }
  }

  Future<void> refreshCurrentUser() => fetchCurrentUser();

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? email,
  }) async {
    final api = ref.read(apiClientProvider);
    final res = await api.patch('/api/v1/auth/me', data: {
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    });
    state = AuthState(status: SessionStatus.loggedIn, user: AppUser.fromJson(res.data));
  }

  Future<void> logout({String? error}) async {
    final storage = ref.read(localStorageProvider);
    await storage.clearTokens();
    state = AuthState(status: SessionStatus.loggedOut, error: error);
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
