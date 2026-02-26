import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/api_endpoints.dart';

/// Service Supabase pour Aura Finance
/// Gère l'initialisation et fournit l'accès au client
class SupabaseService {
  SupabaseService._();
  
  static final SupabaseService _instance = SupabaseService._();
  static SupabaseService get instance => _instance;
  
  bool _initialized = false;
  
  /// Initialise Supabase
  Future<void> initialize() async {
    if (_initialized) return;
    
    await Supabase.initialize(
      url: ApiEndpoints.supabaseUrl,
      anonKey: ApiEndpoints.supabaseAnonKey,
      debug: true,
    );
    
    _initialized = true;
  }
  
  /// Client Supabase
  SupabaseClient get client => Supabase.instance.client;
  
  /// Auth
  GoTrueClient get auth => client.auth;
  
  /// Database
  SupabaseQueryBuilder get profiles => client.from('profiles');
  SupabaseQueryBuilder get accounts => client.from('accounts');
  SupabaseQueryBuilder get transactions => client.from('transactions');
  SupabaseQueryBuilder get subscriptions => client.from('subscriptions');
  SupabaseQueryBuilder get aiInsights => client.from('ai_insights');
  SupabaseQueryBuilder get budgetGoals => client.from('budget_goals');
  
  /// Storage
  SupabaseStorageClient get storage => client.storage;
  
  /// Realtime
  RealtimeClient get realtime => client.realtime;
  
  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => auth.currentUser != null;
  
  /// Utilisateur actuel
  User? get currentUser => auth.currentUser;
  
  /// ID de l'utilisateur actuel
  String? get currentUserId => auth.currentUser?.id;
  
  /// Stream d'état d'authentification
  Stream<AuthState> get authStateChanges => auth.onAuthStateChange;
}

/// Extension pour faciliter les requêtes
extension SupabaseQueryExtension on SupabaseQueryBuilder {
  /// Filtre par user_id
  PostgrestFilterBuilder<PostgrestList> forCurrentUser() {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return eq('user_id', userId);
  }
}
