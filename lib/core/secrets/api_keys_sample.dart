/// Fichier de configuration des clés API - À REMPLACER PAR VOS VRAIES CLÉS
/// 
///⚠ IMPORTANT :
/// 1. Remplacez toutes les valeurs par vos vraies clés
/// 2. Ne commitez jamais ce fichier avec les vraies clés
/// 3. Utilisez les variables d'environnement en production

class ApiKeys {
  ApiKeys._();
  
  //════════════════════════════════════════════════════════════
  // OPENAI API - Pour l'IA (scan, coach, insights)
  //═══════════════════════════════════════════════════════════
  /// Remplacez par votre clé API OpenAI
  /// Obtenir sur : https://platform.openai.com/api-keys
  static const String openaiApiKey = 'sk-YOUR_OPENAI_API_KEY_HERE';
  
  //═══════════════════════════════════════════════════════════
  // DEEPSEEK API - Prioritaire pour le coach IA (moins cher)
  //═══════════════════════════════════════════════════════════
  /// Remplacez par votre clé API DeepSeek (fallback)
  /// Obtenir sur : https://platform.deepseek.com/api-keys
  static const String deepseekApiKey = 'sk-YOUR_DEEPSEEK_API_KEY_HERE';
  
  //═══════════════════════════════════════════════════════════
  // GOOGLE GEMINI API - Fallback pour le scan
  //═══════════════════════════════════════════════════════════
  /// Remplacez par votre clé API Gemini
  /// Obtenir sur : https://aistudio.google.com/app/apikey
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  
  //═══════════════════════════════════════════════════════════
  // SUPABASE SERVICE ROLE KEY
  //⚠ À utiliser uniquement dans les Edge Functions
  // NE PAS L'INCLURE DANS LE CLIENT FLUTTER
  //═══════════════════════════════════════════════════════════
  /// Supabase Service Role Key (Edge Functions)
  static const String supabaseServiceRoleKey = 'YOUR_SUPABASE_SERVICE_ROLE_KEY_HERE';
  
  //═══════════════════════════════════════════════════════════
  // API EXTÉRIEURES (Bonus)
  //═══════════════════════════════════════════════════════════
  /// ExchangeRate API (conversion monnaies)
  static const String exchangeRateApiKey = 'YOUR_EXCHANGERATE_API_KEY_HERE';
}
