import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/models/shared_account_model.dart';

/// Carte glassmorphique affichant un compte partagé
class SharedAccountCard extends ConsumerWidget {
  final SharedAccount account;
  final VoidCallback? onTap;
  final bool showBadge;

  const SharedAccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberCount = account.members?.length ?? 1;
    final isPro = account.isProFeature;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: AuraDimensions.radiusXL,
        padding: const EdgeInsets.all(AuraDimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône et badge
            Row(
              children: [
                // Icône du compte
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(int.parse(account.color.replaceFirst('#', '0xFF'))),
                        Color(int.parse(account.color.replaceFirst('#', '0xFF'))).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                  ),
                  child: Icon(
                    _getIconData(account.icon),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AuraDimensions.spaceM),
                
                // Nom et type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: AuraTypography.h4.copyWith(
                          color: AuraColors.auraTextDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildModeChip(account.sharingMode),
                          if (isPro) ...[
                            const SizedBox(width: 8),
                            _buildProBadge(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Flèche
                Icon(
                  Icons.chevron_right,
                  color: AuraColors.auraTextDarkSecondary,
                ),
              ],
            ),

            const SizedBox(height: AuraDimensions.spaceL),

            // Solde
            Text(
              '${account.totalBalance >= 0 ? '+' : ''}${account.totalBalance.toStringAsFixed(2)} €',
              style: AuraTypography.hero.copyWith(
                color: account.totalBalance >= 0 
                    ? AuraColors.auraGreen 
                    : AuraColors.auraRed,
                fontSize: 32,
              ),
            ),

            const SizedBox(height: AuraDimensions.spaceS),

            // Dépenses du mois
            Text(
              'Dépenses ce mois: ${account.totalExpensesThisMonth.toStringAsFixed(2)} €',
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
            ),

            const SizedBox(height: AuraDimensions.spaceM),

            // Avatars des membres
            Row(
              children: [
                _buildMemberAvatars(),
                const SizedBox(width: AuraDimensions.spaceS),
                Text(
                  '$memberCount membre${memberCount > 1 ? 's' : ''}',
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(SharingMode mode) {
    final (label, color) = switch (mode) {
      SharingMode.couple => ('Couple', AuraColors.auraAccentGold),
      SharingMode.family => ('Famille', AuraColors.auraGreen),
      SharingMode.roommates => ('Coloc', AuraColors.auraAmber),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AuraDimensions.radiusS),
      ),
      child: Text(
        label,
        style: AuraTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AuraColors.auraAmber, AuraColors.auraDeep],
        ),
        borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
      ),
      child: Text(
        'PRO',
        style: AuraTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildMemberAvatars() {
    final members = account.members?.take(4).toList() ?? [];
    
    return SizedBox(
      height: 32,
      child: Stack(
        children: members.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          return Positioned(
            left: index * 20.0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                image: member.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(member.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: AuraColors.auraAmber,
              ),
              child: member.avatarUrl == null
                  ? Center(
                      child: Text(
                        member.effectiveDisplayName.substring(0, 1).toUpperCase(),
                        style: AuraTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconData(String icon) {
    return switch (icon) {
      'people' => Icons.people_outline,
      'family' => Icons.family_restroom_outlined,
      'home' => Icons.home_outlined,
      'favorite' => Icons.favorite_outline,
      'wallet' => Icons.account_balance_wallet_outlined,
      _ => Icons.people_outline,
    };
  }
}

/// Carte compacte pour le dashboard
class SharedAccountCompactCard extends StatelessWidget {
  final SharedAccount account;
  final VoidCallback? onTap;

  const SharedAccountCompactCard({
    super.key,
    required this.account,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: AuraDimensions.radiusL,
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(int.parse(account.color.replaceFirst('#', '0xFF'))),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
              ),
              child: Icon(
                _getIconData(account.icon),
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AuraDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: AuraTypography.labelLarge.copyWith(
                      color: AuraColors.auraTextDark,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${account.members?.length ?? 1} membres',
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${account.totalBalance >= 0 ? '+' : ''}${account.totalBalance.toStringAsFixed(0)}€',
              style: AuraTypography.h4.copyWith(
                color: account.totalBalance >= 0
                    ? AuraColors.auraGreen
                    : AuraColors.auraRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String icon) {
    return switch (icon) {
      'people' => Icons.people_outline,
      'family' => Icons.family_restroom_outlined,
      'home' => Icons.home_outlined,
      'favorite' => Icons.favorite_outline,
      'wallet' => Icons.account_balance_wallet_outlined,
      _ => Icons.people_outline,
    };
  }
}
