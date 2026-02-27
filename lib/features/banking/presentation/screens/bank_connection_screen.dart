import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/aura_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../domain/banking_models.dart';
import '../../services/banking_service.dart';

/// Écran de connexion à une banque
class BankConnectionScreen extends ConsumerStatefulWidget {
  final String? preselectedBank;
  
  const BankConnectionScreen({
    super.key,
    this.preselectedBank,
  });

  @override
  ConsumerState<BankConnectionScreen> createState() => _BankConnectionScreenState();
}

class _BankConnectionScreenState extends ConsumerState<BankConnectionScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedBankId;
  bool _isConnecting = false;
  String? _authUrl;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedBank != null) {
      _selectedBankId = widget.preselectedBank;
    }
  }

  List<Map<String, dynamic>> get _filteredBanks {
    if (_searchQuery.isEmpty) return FrenchBanks.banks;
    return FrenchBanks.search(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.background,
      body: _authUrl != null
          ? _buildWebView()
          : _buildBankSelection(),
    );
  }

  Widget _buildBankSelection() {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        
        // Recherche
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSearchBar(),
          ),
        ),
        
        // Liste des banques
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final bank = _filteredBanks[index];
                return _buildBankTile(bank);
              },
              childCount: _filteredBanks.length,
            ),
          ),
        ),
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AuraColors.amber.withOpacity(0.3),
            AuraColors.background,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Choisir sa banque',
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connexion sécurisée via Open Banking',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: AuraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher une banque...',
          hintStyle: GoogleFonts.dmSans(
            color: AuraColors.textSecondary,
          ),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: AuraColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AuraColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildBankTile(Map<String, dynamic> bank) {
    final isSelected = _selectedBankId == bank['id'];
    
    return GestureDetector(
      onTap: () => _selectBank(bank['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AuraColors.amber.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AuraColors.amber : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                image: bank['logo'] != null
                    ? DecorationImage(
                        image: NetworkImage(bank['logo']!),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: bank['logo'] == null
                  ? const Icon(Icons.account_balance, color: Colors.white54)
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Nom
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank['name']!,
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connexion sécurisée',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AuraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Sélection
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AuraColors.amber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return Column(
      children: [
        // Header WebView
        Container(
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
          decoration: BoxDecoration(
            color: AuraColors.background,
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _authUrl = null),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  'Connexion bancaire',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        
        // WebView
        Expanded(
          child: WebViewWidget(
            controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setNavigationDelegate(
                NavigationDelegate(
                  onNavigationRequest: (request) {
                    // Intercepter le callback
                    if (request.url.startsWith('aura.finance://callback')) {
                      _handleCallback(request.url);
                      return NavigationDecision.prevent;
                    }
                    return NavigationDecision.navigate;
                  },
                  onPageFinished: (url) {
                    // Injecter du CSS pour améliorer l'apparence
                    _injectCustomCSS();
                  },
                ),
              )
              ..loadRequest(Uri.parse(_authUrl!)),
          ),
        ),
        
        // Footer sécurité
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AuraColors.background,
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, color: AuraColors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                'Connexion chiffrée et sécurisée',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AuraColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectBank(String bankId) {
    HapticService.mediumTap();
    setState(() => _selectedBankId = bankId);
    
    // Afficher confirmation
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildConfirmationSheet(bankId),
    );
  }

  Widget _buildConfirmationSheet(String bankId) {
    final bank = FrenchBanks.banks.firstWhere((b) => b['id'] == bankId);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AuraColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              image: bank['logo'] != null
                  ? DecorationImage(
                      image: NetworkImage(bank['logo']!),
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            bank['name']!,
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous allez être redirigé vers votre banque',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: AuraColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Info sécurité
          GlassCard(
            borderRadius: 12,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.security, color: AuraColors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aura Finance ne stocke jamais vos identifiants bancaires',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AuraColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Boutons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _startConnection(bankId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AuraColors.amber, AuraColors.deep],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Continuer',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startConnection(String bankId) async {
    setState(() => _isConnecting = true);
    
    try {
      final authUrl = await BankingService.instance.connectBank(
        institutionId: bankId,
        provider: 'bridge',
      );
      
      setState(() {
        _authUrl = authUrl;
        _isConnecting = false;
      });
    } catch (e) {
      setState(() => _isConnecting = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: $e',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AuraColors.red,
          ),
        );
      }
    }
  }

  void _handleCallback(String url) {
    // Extraire le code d'autorisation
    final uri = Uri.parse(url);
    final code = uri.queryParameters['code'];
    
    if (code != null && _selectedBankId != null) {
      _completeConnection(code);
    }
  }

  Future<void> _completeConnection(String code) async {
    setState(() => _isConnecting = true);
    
    try {
      await BankingService.instance.handleOAuthCallback(
        code: code,
        institutionId: _selectedBankId!,
        provider: 'bridge',
      );
      
      if (mounted) {
        context.pop(); // Retour à l'écran banking
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Compte connecté avec succès !',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AuraColors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _authUrl = null;
        _isConnecting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur de connexion: $e',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AuraColors.red,
          ),
        );
      }
    }
  }

  void _injectCustomCSS() {
    // Améliorer l'apparence de la page bancaire
    // Cette méthode serait appelée pour injecter du CSS
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
