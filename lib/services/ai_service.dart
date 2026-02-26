import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/constants/api_endpoints.dart';
import 'supabase_service.dart';

/// Service IA pour Aura Finance
/// Gère les appels aux Edge Functions pour l'IA
class AIService {
  AIService._();
  
  static final AIService _instance = AIService._();
  static AIService get instance => _instance;
  
  final _client = http.Client();
  
  String get _baseUrl => ApiEndpoints.supabaseUrl;
  String get _functionsBase => ApiEndpoints.functionsBase;
  
  Map<String, String> get _headers {
    final token = SupabaseService.instance.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  // ═══════════════════════════════════════════════════════════
  // SCAN & OCR
  // ═══════════════════════════════════════════════════════════
  
  /// Scan un ticket de caisse ou facture
  Future<ScanResult> scanReceipt(Uint8List imageBytes, {String? mimeType}) async {
    try {
      final base64Image = base64Encode(imageBytes);
      
      final response = await _client.post(
        Uri.parse('$_baseUrl${_functionsBase}/scan-receipt'),
        headers: _headers,
        body: jsonEncode({
          'image': base64Image,
          'mimeType': mimeType ?? 'image/jpeg',
        }),
      ).timeout(ApiEndpoints.aiTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ScanResult.fromJson(data);
      } else {
        throw Exception('Scan failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Scan error: $e');
    }
  }
  
  /// Traite une commande vocale
  Future<VoiceResult> processVoice(String transcript) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl${_functionsBase}/process-voice'),
        headers: _headers,
        body: jsonEncode({'transcript': transcript}),
      ).timeout(ApiEndpoints.aiTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VoiceResult.fromJson(data);
      } else {
        throw Exception('Voice processing failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Voice error: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // PRÉDICTIONS
  // ═══════════════════════════════════════════════════════════
  
  /// Prédit le solde sur 30 jours
  Future<PredictionResult> predictBalance() async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl${_functionsBase}/predict-balance'),
        headers: _headers,
      ).timeout(ApiEndpoints.aiTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PredictionResult.fromJson(data);
      } else {
        throw Exception('Prediction failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Prediction error: $e');
    }
  }
  
  /// Détecte les "vampires" (hausses de prix)
  Future<List<VampireDetection>> detectVampires() async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl${_functionsBase}/detect-vampires'),
        headers: _headers,
      ).timeout(ApiEndpoints.aiTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((e) => VampireDetection.fromJson(e)).toList();
      } else {
        throw Exception('Vampire detection failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Vampire detection error: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // INSIGHTS
  // ═══════════════════════════════════════════════════════════
  
  /// Génère des insights personnalisés
  Future<List<AIInsight>> generateInsights() async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl${_functionsBase}/generate-insights'),
        headers: _headers,
      ).timeout(ApiEndpoints.aiTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((e) => AIInsight.fromJson(e)).toList();
      } else {
        throw Exception('Insights generation failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Insights error: $e');
    }
  }
  
  /// Catégorise une transaction
  Future<CategorizationResult> categorizeTransaction({
    required String description,
    String? merchant,
    double? amount,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl${_functionsBase}/categorize-transaction'),
        headers: _headers,
        body: jsonEncode({
          'description': description,
          'merchant': merchant,
          'amount': amount,
        }),
      ).timeout(ApiEndpoints.aiTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CategorizationResult.fromJson(data);
      } else {
        throw Exception('Categorization failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Categorization error: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // COACH
  // ═══════════════════════════════════════════════════════════
  
  /// Chat avec le coach IA
  Future<CoachResponse> chatWithCoach(String message, {List<Map<String, dynamic>>? history}) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl${_functionsBase}/chat-coach'),
        headers: _headers,
        body: jsonEncode({
          'message': message,
          'history': history ?? [],
        }),
      ).timeout(ApiEndpoints.aiTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CoachResponse.fromJson(data);
      } else {
        throw Exception('Coach chat failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Coach error: $e');
    }
  }
  
  /// Obtient un conseil financier
  Future<String> getFinancialAdvice({String? topic}) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl${_functionsBase}/financial-advice'),
        headers: _headers,
        body: jsonEncode({'topic': topic}),
      ).timeout(ApiEndpoints.aiTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['advice'] as String;
      } else {
        throw Exception('Advice failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Advice error: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════
// MODÈLES
// ═══════════════════════════════════════════════════════════

class ScanResult {
  final double amount;
  final String? merchant;
  final String? category;
  final DateTime? date;
  final String? description;
  final double confidence;
  final Map<String, dynamic>? rawData;
  
  ScanResult({
    required this.amount,
    this.merchant,
    this.category,
    this.date,
    this.description,
    required this.confidence,
    this.rawData,
  });
  
  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      amount: (json['amount'] as num).toDouble(),
      merchant: json['merchant'] as String?,
      category: json['category'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      description: json['description'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      rawData: json,
    );
  }
}

class VoiceResult {
  final double amount;
  final String? merchant;
  final String? category;
  final String? description;
  final double confidence;
  
  VoiceResult({
    required this.amount,
    this.merchant,
    this.category,
    this.description,
    required this.confidence,
  });
  
  factory VoiceResult.fromJson(Map<String, dynamic> json) {
    return VoiceResult(
      amount: (json['amount'] as num).toDouble(),
      merchant: json['merchant'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PredictionResult {
  final List<DailyPrediction> predictions;
  final double currentBalance;
  final String? warning;
  final DateTime? lowestBalanceDate;
  final double? lowestBalance;
  
  PredictionResult({
    required this.predictions,
    required this.currentBalance,
    this.warning,
    this.lowestBalanceDate,
    this.lowestBalance,
  });
  
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      predictions: (json['predictions'] as List)
          .map((e) => DailyPrediction.fromJson(e))
          .toList(),
      currentBalance: (json['currentBalance'] as num).toDouble(),
      warning: json['warning'] as String?,
      lowestBalanceDate: json['lowestBalanceDate'] != null
          ? DateTime.parse(json['lowestBalanceDate'])
          : null,
      lowestBalance: json['lowestBalance'] != null
          ? (json['lowestBalance'] as num).toDouble()
          : null,
    );
  }
}

class DailyPrediction {
  final DateTime date;
  final double predictedBalance;
  final String? status; // 'safe', 'warning', 'danger'
  
  DailyPrediction({
    required this.date,
    required this.predictedBalance,
    this.status,
  });
  
  factory DailyPrediction.fromJson(Map<String, dynamic> json) {
    return DailyPrediction(
      date: DateTime.parse(json['date']),
      predictedBalance: (json['predictedBalance'] as num).toDouble(),
      status: json['status'] as String?,
    );
  }
}

class VampireDetection {
  final String subscriptionId;
  final String name;
  final double oldAmount;
  final double newAmount;
  final double increasePercentage;
  final DateTime detectedAt;
  
  VampireDetection({
    required this.subscriptionId,
    required this.name,
    required this.oldAmount,
    required this.newAmount,
    required this.increasePercentage,
    required this.detectedAt,
  });
  
  factory VampireDetection.fromJson(Map<String, dynamic> json) {
    return VampireDetection(
      subscriptionId: json['subscriptionId'] as String,
      name: json['name'] as String,
      oldAmount: (json['oldAmount'] as num).toDouble(),
      newAmount: (json['newAmount'] as num).toDouble(),
      increasePercentage: (json['increasePercentage'] as num).toDouble(),
      detectedAt: DateTime.parse(json['detectedAt']),
    );
  }
}

class AIInsight {
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final int priority;
  
  AIInsight({
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.priority,
  });
  
  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      priority: json['priority'] as int? ?? 5,
    );
  }
}

class CategorizationResult {
  final String category;
  final String? subcategory;
  final double confidence;
  final List<String>? alternatives;
  
  CategorizationResult({
    required this.category,
    this.subcategory,
    required this.confidence,
    this.alternatives,
  });
  
  factory CategorizationResult.fromJson(Map<String, dynamic> json) {
    return CategorizationResult(
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      alternatives: (json['alternatives'] as List?)?.cast<String>(),
    );
  }
}

class CoachResponse {
  final String message;
  final List<CoachAction>? suggestedActions;
  final Map<String, dynamic>? data;
  
  CoachResponse({
    required this.message,
    this.suggestedActions,
    this.data,
  });
  
  factory CoachResponse.fromJson(Map<String, dynamic> json) {
    return CoachResponse(
      message: json['message'] as String,
      suggestedActions: (json['suggestedActions'] as List?)
          ?.map((e) => CoachAction.fromJson(e))
          .toList(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

class CoachAction {
  final String label;
  final String action;
  final Map<String, dynamic>? params;
  
  CoachAction({
    required this.label,
    required this.action,
    this.params,
  });
  
  factory CoachAction.fromJson(Map<String, dynamic> json) {
    return CoachAction(
      label: json['label'] as String,
      action: json['action'] as String,
      params: json['params'] as Map<String, dynamic>?,
    );
  }
}
