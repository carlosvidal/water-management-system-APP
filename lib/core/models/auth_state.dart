import 'package:water_readings_app/core/models/user.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? refreshToken;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.refreshToken,
    this.error,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated({
    required User user,
    required String token,
    String? refreshToken,
  }) : this(
          status: AuthStatus.authenticated,
          user: user,
          token: token,
          refreshToken: refreshToken,
        );

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.error(String error) : this(
          status: AuthStatus.error,
          error: error,
        );

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? refreshToken,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user == other.user &&
          token == other.token &&
          refreshToken == other.refreshToken &&
          error == other.error;

  @override
  int get hashCode =>
      status.hashCode ^
      user.hashCode ^
      token.hashCode ^
      refreshToken.hashCode ^
      error.hashCode;

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.name}, hasToken: ${token != null}, error: $error)';
  }
}