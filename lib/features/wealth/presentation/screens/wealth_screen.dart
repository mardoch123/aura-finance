import 'package:flutter/material.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/widgets/glass_card.dart';

class WealthScreen extends StatefulWidget {
  const WealthScreen({super.key});

  @override
  State<WealthScreen> createState() => _WealthScreenState();
}

class _WealthScreenState extends State<WealthScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _overview;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _overview = {
        'total_wealth': 245000.0,
        'total_invested': 210000.0,
        'total_performance': 35000.0,
        'total_performance_percent': 16.7,
        'accounts': [
          {
            'name': 'Assurance Vie BNP',
            'type': 'life_insurance',
            'value': 85000.0,
            'invested': 75000.0,
            'performance': 10000.0,
            'color': '#E8A86C',
          },
          {
            'name': 'PEA BoursoBank',
            'type': 'pea',
            'value': 62000.0,
            'invested': 55000.0,
            'performance': 7000.0,
            'color': '#7DC983',
          },
          {
            'name': 'Bitcoin',
            'type': 'crypto',
            'value': 48000.0,
            'invested': 30000.0,
            'performance': 18000.0,
            'color': '#F0C080',
          },
          {
            'name': 'Appartement Lyon',
            'type': 'real_estate',
            'value': 50000.0,
            'invested': 50000.0,
            'performance': 0.0,
            'color': '#C4714A',
          },
        ],
        'allocation': {
          'life_insurance': 34.7,
          'pea': 25.3,
          'crypto': 19.6,
          'real_estate': 20.4,
        },
        'alerts': [
          {
            'type': 'rebalancing_needed',
            'severity': 'warning',
            'title': 'Rééquilibrage nécessaire',
            'description': 'Votre allocation crypto dépasse 20% de l\'objectif',
          },
        ],
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AuraColors.auraDark.withOpacity(0.5),
                    AuraColors.auraDeep.withOpacity(0.3),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patrimoine',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Suivez et optimisez votre patrimoine',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticService.mediumTap();
                          _showAddAccountDialog();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AuraColors.auraAmber,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Total patrimoine
                  _buildTotalWealthCard(),
                  const SizedBox(height: 20),

                  // Alertes
                  if (_overview?['alerts']?.isNotEmpty ?? false) ...[
                    _buildAlertsSection(),
                    const SizedBox(height: 20),
                  ],

                  // Allocation
                  _buildAllocationSection(),
                  const SizedBox(height: 20),

                  // Comptes
                  _buildAccountsSection(),
                  const SizedBox(height: 20),

                  // Actions rapides
                  _buildQuickActions(),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalWealthCard() {
    final totalWealth = _overview?['total_wealth'] ?? 0.0;
    final performance = _overview?['total_performance'] ?? 0.0;
    final performancePercent = _overview?['total_performance_percent'] ?? 0.0;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Valeur totale du patrimoine',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${totalWealth.toStringAsFixed(0)}€',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: performance >= 0
                    ? AuraColors.auraGreen.withOpacity(0.2)
                    : AuraColors.auraRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    performance >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: performance >= 0 ? AuraColors.auraGreen : AuraColors.auraRed,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${performance >= 0 ? '+' : ''}${performance.toStringAsFixed(0)}€ (${performancePercent.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: performance >= 0 ? AuraColors.auraGreen : AuraColors.auraRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    final alerts = _overview?['alerts'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alertes',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...alerts.map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String;
    final color = severity == 'critical'
        ? AuraColors.auraRed
        : severity == 'warning'
            ? AuraColors.auraAmber
            : AuraColors.auraGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  alert['description'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: color, size: 16),
        ],
      ),
    );
  }

  Widget _buildAllocationSection() {
    final allocation = _overview?['allocation'] as Map<String, dynamic>? ?? {};

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition du patrimoine',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Graphique circulaire simplifié
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AuraColors.auraAmber,
                        AuraColors.auraGreen,
                        AuraColors.auraDeep,
                        AuraColors.auraDark,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraColors.auraBackground,
                      ),
                      child: Center(
                        child: Text(
                          '100%',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: allocation.entries.map((entry) {
                      final typeLabels = {
                        'life_insurance': 'Assurance Vie',
                        'pea': 'PEA',
                        'crypto': 'Crypto',
                        'real_estate': 'Immobilier',
                      };
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getTypeColor(entry.key),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                typeLabels[entry.key] ?? entry.key,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              '${(entry.value as num).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    return switch (type) {
      'life_insurance' => AuraColors.auraAmber,
      'pea' => AuraColors.auraGreen,
      'crypto' => AuraColors.auraDeep,
      'real_estate' => AuraColors.auraDark,
      _ => Colors.grey,
    };
  }

  Widget _buildAccountsSection() {
    final accounts = _overview?['accounts'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mes comptes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: _showAddAccountDialog,
              child: Text(
                '+ Ajouter',
                style: TextStyle(
                  color: AuraColors.auraAmber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...accounts.map((account) => _buildAccountCard(account)),
      ],
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final performance = account['performance'] as double;
    final performancePercent = account['invested'] > 0
        ? (performance / account['invested'] * 100)
        : 0.0;

    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(int.parse(account['color'].replaceFirst('#', '0xFF'))),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getAccountIcon(account['type']),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${account['value'].toStringAsFixed(0)}€',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${performance >= 0 ? '+' : ''}${performance.toStringAsFixed(0)}€',
                  style: TextStyle(
                    color: performance >= 0 ? AuraColors.auraGreen : AuraColors.auraRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${performance >= 0 ? '+' : ''}${performancePercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: performance >= 0 ? AuraColors.auraGreen : AuraColors.auraRed,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    return switch (type) {
      'life_insurance' => Icons.shield,
      'pea' => Icons.trending_up,
      'crypto' => Icons.currency_bitcoin,
      'real_estate' => Icons.home,
      _ => Icons.account_balance,
    };
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Planification',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.elderly,
                title: 'Retraite',
                subtitle: 'Projection',
                color: AuraColors.auraAmber,
                onTap: () => _showRetirementProjection(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.family_restroom,
                title: 'Succession',
                subtitle: 'Simulation',
                color: AuraColors.auraDeep,
                onTap: () => _showSuccessionSimulation(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog() {
    // Show add account dialog
  }

  void _showRetirementProjection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RetirementProjectionSheet(),
    );
  }

  void _showSuccessionSimulation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SuccessionSimulationSheet(),
    );
  }
}

class _RetirementProjectionSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AuraColors.auraBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Projection Retraite',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estimation de vos revenus à la retraite',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          _buildScenarioCard(
            title: 'Scénario optimiste',
            returnRate: '6%',
            projectedWealth: '850 000€',
            monthlyPension: '2 833€',
            color: AuraColors.auraGreen,
          ),
          const SizedBox(height: 16),
          _buildScenarioCard(
            title: 'Scénario réaliste',
            returnRate: '4%',
            projectedWealth: '620 000€',
            monthlyPension: '2 066€',
            color: AuraColors.auraAmber,
            isRecommended: true,
          ),
          const SizedBox(height: 16),
          _buildScenarioCard(
            title: 'Scénario prudent',
            returnRate: '2%',
            projectedWealth: '450 000€',
            monthlyPension: '1 500€',
            color: AuraColors.auraRed,
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard({
    required String title,
    required String returnRate,
    required String projectedWealth,
    required String monthlyPension,
    required Color color,
    bool isRecommended = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended ? color : color.withOpacity(0.3),
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Recommandé',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Rendement annualisé : $returnRate',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patrimoine',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      projectedWealth,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pension mensuelle',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      monthlyPension,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessionSimulationSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AuraColors.auraBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Simulation Succession',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estimation des droits de succession',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          _buildInputField('Valeur totale des biens', '450 000€'),
          const SizedBox(height: 16),
          _buildInputField('Dettes', '50 000€'),
          const SizedBox(height: 16),
          _buildInputField('Situation familiale', 'Marié, 2 enfants'),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AuraColors.auraAmber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AuraColors.auraAmber.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _buildResultRow('Patrimoine net', '400 000€'),
                const Divider(color: Colors.white24),
                _buildResultRow('Droits de succession estimés', '45 000€', isNegative: true),
                const Divider(color: Colors.white24),
                _buildResultRow('Héritage net', '355 000€', isHighlighted: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Icon(
                Icons.edit,
                color: Colors.white.withOpacity(0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, {bool isNegative = false, bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isNegative
                  ? AuraColors.auraRed
                  : isHighlighted
                      ? AuraColors.auraGreen
                      : Colors.white,
              fontSize: 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}