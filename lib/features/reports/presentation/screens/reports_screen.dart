import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/theme/aura_dimensions.dart';
import '../../../../core/theme/aura_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../data/models/report_models.dart';

/// Écran principal des Rapports
class ReportsScreen extends ConsumerStatefulWidget {
  static const routeName = '/reports';

  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: Connect to actual provider
    final templates = _getMockTemplates();
    final recentReports = _getMockReports();

    return Scaffold(
      backgroundColor: AuraColors.auraBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),

            // Rapports récents
            if (recentReports.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildRecentReportsSection(recentReports),
              ),
            ],

            // Templates disponibles
            SliverPadding(
              padding: const EdgeInsets.all(AuraDimensions.spaceM),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Générer un rapport',
                  style: AuraTypography.h4.copyWith(
                    color: AuraColors.auraTextDark,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final template = templates[index];
                    return _buildTemplateCard(template);
                  },
                  childCount: templates.length,
                ),
              ),
            ),

            const SliverPadding(
              padding: EdgeInsets.only(bottom: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AuraDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(AuraDimensions.spaceS),
                  decoration: BoxDecoration(
                    color: AuraColors.auraGlass,
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AuraColors.auraTextDark,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AuraDimensions.spaceL),
          Text(
            'Rapports',
            style: AuraTypography.h1.copyWith(
              color: AuraColors.auraTextDark,
            ),
          ),
          const SizedBox(height: AuraDimensions.spaceXS),
          Text(
            'Exportez vos données pour la fiscalité, les prêts ou votre analyse personnelle',
            style: AuraTypography.bodyLarge.copyWith(
              color: AuraColors.auraTextDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportsSection(List<GeneratedReport> reports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rapports récents',
                style: AuraTypography.h4.copyWith(
                  color: AuraColors.auraTextDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Voir tout',
                  style: AuraTypography.labelMedium.copyWith(
                    color: AuraColors.auraDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceM),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AuraDimensions.spaceM),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildRecentReportCard(report);
            },
          ),
        ),
        const SizedBox(height: AuraDimensions.spaceL),
      ],
    );
  }

  Widget _buildRecentReportCard(GeneratedReport report) {
    final color = Color(int.parse(report.template?.color?.replaceFirst('#', '0xFF') ?? '0xFFE8A86C'));

    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        // TODO: Open report
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: AuraDimensions.spaceM),
        child: GlassCard(
          borderRadius: AuraDimensions.radiusXL,
          padding: const EdgeInsets.all(AuraDimensions.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
                    ),
                    child: Icon(
                      report.template?.iconData ?? Icons.description,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (report.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AuraColors.auraGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PDF',
                        style: AuraTypography.labelSmall.copyWith(
                          color: AuraColors.auraGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                report.name,
                style: AuraTypography.labelMedium.copyWith(
                  color: AuraColors.auraTextDark,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                report.periodLabel,
                style: AuraTypography.bodySmall.copyWith(
                  color: AuraColors.auraTextDarkSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.download,
                    size: 14,
                    color: AuraColors.auraTextDarkSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${report.downloadCount}',
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    report.fileSizeFormatted,
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(ReportTemplate template) {
    final color = Color(int.parse(template.color.replaceFirst('#', '0xFF')));

    return GestureDetector(
      onTap: () {
        HapticService.mediumTap();
        _showReportGenerationDialog(template);
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: AuraDimensions.spaceM),
        borderRadius: AuraDimensions.radiusXL,
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
              ),
              child: Icon(
                template.iconData,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AuraDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        template.name,
                        style: AuraTypography.labelLarge.copyWith(
                          color: AuraColors.auraTextDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (template.isProFeature) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AuraColors.auraAmber, AuraColors.auraDeep],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRO',
                            style: AuraTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.auraTextDarkSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AuraDimensions.radiusXS),
                        ),
                        child: Text(
                          template.typeLabel,
                          style: AuraTypography.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...template.availableFormats.map((format) {
                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AuraColors.auraGlass,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            format.name.toUpperCase(),
                            style: AuraTypography.labelSmall.copyWith(
                              color: AuraColors.auraTextDarkSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AuraColors.auraTextDarkSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showReportGenerationDialog(ReportTemplate template) {
    // TODO: Show report configuration dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ReportGenerationSheet(template: template),
    );
  }

  List<ReportTemplate> _getMockTemplates() {
    return [
      ReportTemplate(
        id: '1',
        code: 'tax_declaration_2042',
        name: 'Déclaration Fiscale 2042',
        description: 'Rapport complet pour votre déclaration d\'impôts avec catégorisation automatique des déductions',
        type: ReportType.taxDeclaration,
        availableFormats: [ReportFormat.pdf, ReportFormat.excel],
        icon: 'account_balance',
        color: '#7DC983',
        isProFeature: true,
        displayOrder: 1,
        createdAt: DateTime.now(),
      ),
      ReportTemplate(
        id: '2',
        code: 'annual_analysis',
        name: 'Analyse Annuelle',
        description: 'Vue d\'ensemble complète de votre année financière avec tendances et insights',
        type: ReportType.annualAnalysis,
        availableFormats: [ReportFormat.pdf, ReportFormat.excel],
        icon: 'analytics',
        color: '#E8A86C',
        isProFeature: false,
        displayOrder: 2,
        createdAt: DateTime.now(),
      ),
      ReportTemplate(
        id: '3',
        code: 'loan_application',
        name: 'Dossier de Prêt',
        description: 'Document professionnel pour votre demande de prêt immobilier ou consommation',
        type: ReportType.loanApplication,
        availableFormats: [ReportFormat.pdf],
        icon: 'home',
        color: '#6B8DD6',
        isProFeature: true,
        displayOrder: 3,
        createdAt: DateTime.now(),
      ),
      ReportTemplate(
        id: '4',
        code: 'monthly_summary',
        name: 'Résumé Mensuel',
        description: 'Rapport mensuel détaillé de vos revenus et dépenses',
        type: ReportType.monthlySummary,
        availableFormats: [ReportFormat.pdf, ReportFormat.excel],
        icon: 'calendar_month',
        color: '#C4714A',
        isProFeature: false,
        displayOrder: 4,
        createdAt: DateTime.now(),
      ),
      ReportTemplate(
        id: '5',
        code: 'category_breakdown',
        name: 'Répartition par Catégorie',
        description: 'Analyse détaillée de vos dépenses par catégorie',
        type: ReportType.categoryBreakdown,
        availableFormats: [ReportFormat.pdf, ReportFormat.excel],
        icon: 'pie_chart',
        color: '#9B7ED8',
        isProFeature: false,
        displayOrder: 5,
        createdAt: DateTime.now(),
      ),
    ];
  }

  List<GeneratedReport> _getMockReports() {
    return [
      GeneratedReport(
        id: '1',
        userId: 'user1',
        templateId: '4',
        name: 'Résumé - Février 2025',
        periodStart: DateTime(2025, 2, 1),
        periodEnd: DateTime(2025, 2, 28),
        status: ReportStatus.completed,
        pdfUrl: 'https://example.com/report1.pdf',
        fileSizeBytes: 2457600,
        pageCount: 12,
        downloadCount: 3,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        template: ReportTemplate(
          id: '4',
          code: 'monthly_summary',
          name: 'Résumé Mensuel',
          description: '',
          type: ReportType.monthlySummary,
          icon: 'calendar_month',
          color: '#C4714A',
          createdAt: DateTime.now(),
        ),
      ),
      GeneratedReport(
        id: '2',
        userId: 'user1',
        templateId: '2',
        name: 'Analyse 2024',
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 12, 31),
        status: ReportStatus.completed,
        pdfUrl: 'https://example.com/report2.pdf',
        excelUrl: 'https://example.com/report2.xlsx',
        fileSizeBytes: 5242880,
        pageCount: 25,
        downloadCount: 8,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        template: ReportTemplate(
          id: '2',
          code: 'annual_analysis',
          name: 'Analyse Annuelle',
          description: '',
          type: ReportType.annualAnalysis,
          icon: 'analytics',
          color: '#E8A86C',
          createdAt: DateTime.now(),
        ),
      ),
    ];
  }
}

/// Bottom sheet pour la génération de rapport
class _ReportGenerationSheet extends StatefulWidget {
  final ReportTemplate template;

  const _ReportGenerationSheet({required this.template});

  @override
  State<_ReportGenerationSheet> createState() => _ReportGenerationSheetState();
}

class _ReportGenerationSheetState extends State<_ReportGenerationSheet> {
  DateTime _periodStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _periodEnd = DateTime.now();
  List<ReportFormat> _selectedFormats = [ReportFormat.pdf];
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(widget.template.color.replaceFirst('#', '0xFF')));

    return Container(
      padding: const EdgeInsets.all(AuraDimensions.spaceXL),
      decoration: BoxDecoration(
        color: AuraColors.auraBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AuraDimensions.radiusXXL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AuraColors.auraTextDarkSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceXL),

            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                  ),
                  child: Icon(
                    widget.template.iconData,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AuraDimensions.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.template.name,
                        style: AuraTypography.h3.copyWith(
                          color: AuraColors.auraTextDark,
                        ),
                      ),
                      Text(
                        widget.template.description,
                        style: AuraTypography.bodyMedium.copyWith(
                          color: AuraColors.auraTextDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AuraDimensions.spaceXL),

            // Période
            Text(
              'Période',
              style: AuraTypography.labelLarge.copyWith(
                color: AuraColors.auraTextDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceM),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    label: 'Du',
                    date: _periodStart,
                    onTap: () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: AuraDimensions.spaceM),
                Expanded(
                  child: _buildDateButton(
                    label: 'Au',
                    date: _periodEnd,
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AuraDimensions.spaceXL),

            // Format
            Text(
              'Format',
              style: AuraTypography.labelLarge.copyWith(
                color: AuraColors.auraTextDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AuraDimensions.spaceM),
            Row(
              children: widget.template.availableFormats.map((format) {
                final isSelected = _selectedFormats.contains(format);
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          if (_selectedFormats.length > 1) {
                            _selectedFormats.remove(format);
                          }
                        } else {
                          _selectedFormats.add(format);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: AuraDimensions.spaceS),
                      padding: const EdgeInsets.symmetric(vertical: AuraDimensions.spaceM),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : AuraColors.auraGlass,
                        borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            format == ReportFormat.pdf
                                ? Icons.picture_as_pdf
                                : Icons.table_chart,
                            color: isSelected ? color : AuraColors.auraTextDarkSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            format.name.toUpperCase(),
                            style: AuraTypography.labelMedium.copyWith(
                              color: isSelected ? color : AuraColors.auraTextDark,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AuraDimensions.spaceXL),

            // Bouton générer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
                  ),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Générer le rapport'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AuraDimensions.spaceM),
        decoration: BoxDecoration(
          color: AuraColors.auraGlass,
          borderRadius: BorderRadius.circular(AuraDimensions.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.auraTextDarkSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
              style: AuraTypography.labelLarge.copyWith(
                color: AuraColors.auraTextDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _periodStart : _periodEnd,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _periodStart = picked;
        } else {
          _periodEnd = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    
    // TODO: Generate report
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isGenerating = false);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapport généré avec succès !'),
          backgroundColor: AuraColors.auraGreen,
        ),
      );
    }
  }
}
