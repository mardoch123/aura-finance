import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../services/banking_service.dart';

/// Bouton de connexion bancaire pour le dashboard
class BankConnectionButton extends ConsumerWidget {
  const BankConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<SyncStatus>(
      stream: BankingService.instance.syncStream,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final isSyncing = status?.isSyncing ?? false;

        return GestureDetector(
          onTap: () => _onTap(context),
          child: GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AuraColors.amber, AuraColors.deep],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: isSyncing
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSyncing ? 'Synchronisation...' : 'Connecter ma banque',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSyncing
                            ? 'Import des transactions en cours'
                            : 'Import automatique sécurisé',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AuraColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSyncing ? Icons.sync : Icons.arrow_forward_ios,
                  color: AuraColors.amber,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context) {
    HapticService.mediumTap();
    context.push('/banking');
  }
}

/// Badge de statut de synchronisation
class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;

  const SyncStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String text;

    switch (status.state) {
      case SyncState.idle:
        color = AuraColors.textSecondary;
        icon = Icons.check_circle;
        text = 'À jour';
        break;
      case SyncState.connecting:
      case SyncState.awaitingAuth:
      case SyncState.authenticating:
        color = AuraColors.amber;
        icon = Icons.hourglass_top;
        text = 'Connexion...';
        break;
      case SyncState.syncing:
        color = AuraColors.amber;
        icon = Icons.sync;
        text = 'Sync ${status.progress}%';
        break;
      case SyncState.completed:
        color = AuraColors.green;
        icon = Icons.check_circle;
        text = 'Synchronisé';
        break;
      case SyncState.error:
        color = AuraColors.red;
        icon = Icons.error;
        text = 'Erreur';
        break;
      default:
        color = AuraColors.textSecondary;
        icon = Icons.circle;
        text = '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget d'indicateur de connexion bancaire
class BankConnectionIndicator extends StatelessWidget {
  final int connectedAccounts;
  final DateTime? lastSync;

  const BankConnectionIndicator({
    super.key,
    required this.connectedAccounts,
    this.lastSync,
  });

  @override
  Widget build(BuildContext context) {
    if (connectedAccounts == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AuraColors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link,
            color: AuraColors.green,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$connectedAccounts compte${connectedAccounts > 1 ? 's' : ''}',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AuraColors.green,
            ),
          ),
          if (lastSync != null) ...[
            const SizedBox(width: 8),
            Text(
              '• ${_formatTimeAgo(lastSync!)}',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AuraColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inHours < 1) return '${diff.inMinutes}min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
