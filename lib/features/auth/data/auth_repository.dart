import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

/// Repository pour l'authentification
class AuthRepository {
  final _supabase = SupabaseService.instance;
  
  /// Stream d'état d'authentification
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;
  
  /// Utilisateur actuel
  User? get currentUser => _supabase.currentUser;
  
  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => _supabase.isAuthenticated;
  
  /// Connexion avec email/mot de passe
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// Inscription avec email/mot de passe
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }
  
  /// Connexion avec Google
  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutterquickstart://login-callback/',
    );
  }
  
  /// Connexion avec Apple
  Future<bool> signInWithApple() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.flutterquickstart://login-callback/',
    );
  }
  
  /// Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
  
  /// Mise à jour du mot de passe
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
  
  /// Rafraîchissement de la session
  Future<AuthResponse> refreshSession() async {
    return await _supabase.auth.refreshSession();
  }
}
