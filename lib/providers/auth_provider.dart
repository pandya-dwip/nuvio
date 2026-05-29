import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? username;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.username,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.authenticating() => const AuthState(status: AuthStatus.authenticating);
  factory AuthState.authenticated(String username) => AuthState(status: AuthStatus.authenticated, username: username);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, errorMessage: message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial());

  Future<bool> login(String username, String password) async {
    state = AuthState.authenticating();
    
    // Add a slight delay for a premium loading animation effect
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final trimmedUser = username.trim();
    if (trimmedUser == 'Campaign User' && password == 'Camp2020') {
      state = AuthState.authenticated(trimmedUser);
      return true;
    } else {
      String message;
      if (trimmedUser.isEmpty) {
        message = 'Please enter your username';
      } else if (password.isEmpty) {
        message = 'Please enter your password';
      } else {
        message = 'Incorrect username or password';
      }
      state = AuthState.error(message);
      return false;
    }
  }

  void logout() {
    state = AuthState.initial();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
