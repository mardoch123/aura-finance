import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_draft.freezed.dart';
part 'transaction_draft.g.dart';

/// Modèle représentant une transaction en cours de création (brouillon)
/// Utilisé après l'analyse IA d'un ticket ou d'une dictée vocale
@freezed
class TransactionDraft with _$TransactionDraft {
  const TransactionDraft._();
  
  const factory TransactionDraft({
    /// Montant de la transaction (négatif pour dépense, positif pour revenu)
    required double amount,
    
    /// Nom du marchand/commerce
    String? merchant,
    
    /// Catégorie principale
    @Default('other') String category,
    
    /// Sous-catégorie
    String? subcategory,
    
    /// Description courte
    String? description,
    
    /// Date de la transaction
    @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
    DateTime? date,
    
    /// Devise
    @Default('EUR') String currency,
    
    /// Liste des articles (si disponible)
    @Default([]) List<ReceiptItem> items,
    
    /// Confiance de l'IA (0.0 à 1.0)
    @Default(0.0) double confidence,
    
    /// URL de l'image scannée
    String? scanImageUrl,
    
    /// Source de la transaction
    @Default('scan') String source,
    
    /// Erreur si l'analyse a échoué
    String? error,
  }) = _TransactionDraft;

  factory TransactionDraft.fromJson(Map<String, dynamic> json) =>
      _$TransactionDraftFromJson(json);
      
  /// Vérifie si le brouillon est valide
  bool get isValid => amount != 0 && error == null;
  
  /// Vérifie si la confiance est élevée (> 0.8)
  bool get hasHighConfidence => confidence >= 0.8;
  
  /// Vérifie si la confiance est faible (< 0.5)
  bool get hasLowConfidence => confidence < 0.5;
}

/// Représente un article sur un ticket de caisse
@freezed
class ReceiptItem with _$ReceiptItem {
  const factory ReceiptItem({
    required String name,
    required double amount,
    int? quantity,
  }) = _ReceiptItem;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) =>
      _$ReceiptItemFromJson(json);
}

// Helpers pour la sérialisation des dates
DateTime? _dateFromJson(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.parse(value);
  if (value is DateTime) return value;
  return null;
}

String? _dateToJson(DateTime? date) => date?.toIso8601String();
