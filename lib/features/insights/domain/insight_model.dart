import 'package:freezed_annotation/freezed_annotation.dart';

part 'insight_model.freezed.dart';
part 'insight_model.g.dart';

/// Types d'insights IA
enum InsightType {
  prediction,
  alert,
  tip,
  vampire,
  achievement,
}

/// Modèle d'insight IA
@freezed
class Insight with _$Insight {
  const factory Insight({
    required String id,
    required String userId,
    required InsightType type,
    required String title,
    required String body,
    @Default({}) Map<String, dynamic> data,
    @Default(5) int priority,
    @Default(false) bool isRead,
    DateTime? readAt,
    @Default(false) bool actionTaken,
    String? actionType,
    DateTime? expiresAt,
    required DateTime createdAt,
  }) = _Insight;

  factory Insight.fromJson(Map<String, dynamic> json) =>
      _$InsightFromJson(json);
}

/// Extension pour les propriétés calculées
extension InsightExtension on Insight {
  /// Icône associée au type d'insight
  String get typeIcon {
    switch (type) {
      case InsightType.prediction:
        return '🔮';
      case InsightType.alert:
        return '⚠️';
      case InsightType.tip:
        return '💡';
      case InsightType.vampire:
        return '🧛';
      case InsightType.achievement:
        return '🏆';
    }
  }

  /// Couleur associée au type
  String get typeColor {
    switch (type) {
      case InsightType.prediction:
        return '#9B59B6';
      case InsightType.alert:
        return '#E74C3C';
      case InsightType.tip:
        return '#3498DB';
      case InsightType.vampire:
        return '#C0392B';
      case InsightType.achievement:
        return '#F39C12';
    }
  }

  /// Si c'est une alerte prioritaire
  bool get isHighPriority => priority <= 3;

  /// Si l'insight est expiré
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

/// Filtres pour les insights
enum InsightFilter {
  all('Tous'),
  unread('Non lus'),
  alerts('Alertes'),
  predictions('Prédictions'),
  vampires('Vampires'),
  tips('Conseils');

  final String label;
  const InsightFilter(this.label);
}
