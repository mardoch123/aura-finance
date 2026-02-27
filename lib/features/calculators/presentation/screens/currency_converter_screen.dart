import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/animations/hero_number.dart';
import '../../data/exchange_rate_service.dart';
import '../../domain/calculator_models.dart';

/// Convertisseur de devises
class CurrencyConverterScreen extends ConsumerStatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  ConsumerState<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends ConsumerState<CurrencyConverterScreen> {
  final _amountController = TextEditingController(text: '100');
  String _fromCurrency = 'EUR';
  String _toCurrency = 'USD';
  CurrencyConversion? _result;
  bool _isLoading = false;
  List<Map<String, dynamic>> _historicalData = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await ExchangeRateService.instance.initialize();
    await _convert();
    await _loadHistoricalData();
  }

  Future<void> _convert() async {
    final amount = double.tryParse(_amountController.text.replaceAll(' ', '')) ?? 0;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await ExchangeRateService.instance.convert(
        amount: amount,
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
      );
      
      setState(() {
        _result = result;
        _isLoading = false;
      });
      HapticService.lightTap();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHistoricalData() async {
    try {
      final data = await ExchangeRateService.instance.getHistoricalRates(
        currency: _toCurrency,
        days: 30,
      );
      setState(() => _historicalData = data);
    } catch (e) {
      // Ignore
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convert();
    HapticService.mediumTap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: AuraColors.background.withOpacity(0.9),
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            title: Text(
              'Convertisseur',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AuraColors.amber.withOpacity(0.2),
                      AuraColors.background,
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildConverterCard(),
                  const SizedBox(height: 24),
                  if (_result != null) ...[
                    _buildResultSection(),
                    const SizedBox(height: 24),
                    _buildChartSection(),
                  ],
                  const SizedBox(height: 24),
                  _buildPopularConversions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConverterCard() {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Montant
          _buildAmountInput(),
          const SizedBox(height: 20),
          
          // Sélecteurs de devises
          Row(
            children: [
              Expanded(
                child: _buildCurrencySelector(
                  value: _fromCurrency,
                  onChanged: (value) {
                    setState(() => _fromCurrency = value!);
                    _convert();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: _swapCurrencies,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AuraColors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildCurrencySelector(
                  value: _toCurrency,
                  onChanged: (value) {
                    setState(() => _toCurrency = value!);
                    _convert();
                    _loadHistoricalData();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AuraColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.dmSans(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (_) => _convert(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s,.]')),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencySelector({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final currencyInfo = SupportedCurrencies.currencies[value] ?? value;
    final flag = currencyInfo.split(' ').first;
    final name = currencyInfo.split(' ').skip(1).join(' ');

    return GestureDetector(
      onTap: () => _showCurrencyPicker(context, value, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    name,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AuraColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AuraColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    String currentValue,
    ValueChanged<String?> onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AuraColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Choisir une devise',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: SupportedCurrencies.currencies.length,
                itemBuilder: (context, index) {
                  final entry = SupportedCurrencies.currencies.entries.elementAt(index);
                  final isSelected = entry.key == currentValue;
                  
                  return ListTile(
                    leading: Text(
                      entry.value.split(' ').first,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      entry.value.split(' ').skip(1).join(' '),
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      entry.key,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AuraColors.textSecondary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: AuraColors.amber)
                        : null,
                    onTap: () {
                      onChanged(entry.key);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Résultat',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AuraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const CircularProgressIndicator(color: AuraColors.amber)
          else
            Text(
              '${_result!.convertedAmount.toStringAsFixed(2)} $_toCurrency',
              style: GoogleFonts.dmSans(
                fontSize: 40,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            '1 $_fromCurrency = ${_result?.rate.toStringAsFixed(4) ?? '-'} $_toCurrency',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AuraColors.amber,
            ),
          ),
          if (ExchangeRateService.instance.lastUpdate != null)
            Text(
              'Mis à jour : ${_formatTime(ExchangeRateService.instance.lastUpdate!)}',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AuraColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    if (_historicalData.isEmpty) return const SizedBox.shrink();

    final spots = _historicalData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value['rate']);
    }).toList();

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Évolution 30 jours',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(showTitles: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AuraColors.amber,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AuraColors.amber.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularConversions() {
    final popularPairs = [
      ['EUR', 'USD'],
      ['EUR', 'GBP'],
      ['EUR', 'CHF'],
      ['EUR', 'JPY'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conversions rapides',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popularPairs.map((pair) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _fromCurrency = pair[0];
                  _toCurrency = pair[1];
                });
                _convert();
                _loadHistoricalData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: (_fromCurrency == pair[0] && _toCurrency == pair[1])
                      ? AuraColors.amber.withOpacity(0.3)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (_fromCurrency == pair[0] && _toCurrency == pair[1])
                        ? AuraColors.amber
                        : Colors.white10,
                  ),
                ),
                child: Text(
                  '${pair[0]} → ${pair[1]}',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'il y a ${diff.inHours}h';
    return '${time.day}/${time.month} à ${time.hour}h${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
