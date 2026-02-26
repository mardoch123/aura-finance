import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.freezed.dart';

/// État d'authentification
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error(String message) = AuthError;
}

/// État du formulaire de connexion
@freezed
class LoginFormState with _$LoginFormState {
  const factory LoginFormState({
    @Default('') String email,
    @Default('') String password,
    @Default(false) bool isLoading,
    @Default(false) bool isObscure,
    String? errorMessage,
  }) = _LoginFormState;
}

/// État du formulaire d'inscription
@freezed
class RegisterFormState with _$RegisterFormState {
  const factory RegisterFormState({
    @Default('') String fullName,
    @Default('') String email,
    @Default('') String password,
    @Default('') String confirmPassword,
    @Default(false) bool isLoading,
    @Default(false) bool isObscure,
    String? errorMessage,
  }) = _RegisterFormState;
}
