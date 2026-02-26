import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

part 'auth_controller.g.dart';

/// Provider du repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Controller d'authentification
@riverpod
class AuthController extends _$AuthController {
  late final AuthRepository _repository;
  
  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    
    // Écoute les changements d'état d'authentification
    _repository.authStateChanges.listen((authState) {
      final event = authState.event;
      final session = authState.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        state = AuthState.authenticated(session.user);
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AuthState.unauthenticated();
      } else if (event == AuthChangeEvent.userUpdated && session != null) {
        state = AuthState.authenticated(session.user);
      }
    });
    
    // Vérifie l'état initial
    final user = _repository.currentUser;
    if (user != null) {
      return AuthState.authenticated(user);
    }
    return const AuthState.initial();
  }
  
  /// Connexion avec email/mot de passe
  Future<void> signInWithEmail(String email, String password) async {
    state = const AuthState.loading();
    try {
      final response = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = AuthState.authenticated(response.user!);
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  /// Inscription
  Future<void> signUp(String email, String password, String fullName) async {
    state = const AuthState.loading();
    try {
      final response = await _repository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      if (response.user != null) {
        state = AuthState.authenticated(response.user!);
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  /// Déconnexion
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState.unauthenticated();
  }
  
  /// Connexion avec Google
  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    try {
      await _repository.signInWithGoogle();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  /// Connexion avec Apple
  Future<void> signInWithApple() async {
    state = const AuthState.loading();
    try {
      await _repository.signInWithApple();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}

/// Provider de l'état du formulaire de connexion
@riverpod
class LoginFormController extends _$LoginFormController {
  @override
  LoginFormState build() {
    return const LoginFormState();
  }
  
  void setEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }
  
  void setPassword(String password) {
    state = state.copyWith(password: password, errorMessage: null);
  }
  
  void toggleObscure() {
    state = state.copyWith(isObscure: !state.isObscure);
  }
  
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
  
  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }
  
  Future<void> submit() async {
    if (state.email.isEmpty || state.password.isEmpty) {
      state = state.copyWith(errorMessage: 'Veuillez remplir tous les champs');
      return;
    }
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await ref.read(authControllerProvider.notifier).signInWithEmail(
        state.email,
        state.password,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email ou mot de passe incorrect',
      );
    }
  }
}
