import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/aura_colors.dart';
import '../theme/aura_dimensions.dart';
import '../haptics/haptic_service.dart';
import 'glass_card.dart';

/// Scaffold principal avec Bottom Navigation glassmorphique
/// et FAB central pour le scanner
class MainScaffold extends StatefulWidget {
  const MainScaffold({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Transactions',
      route: '/transactions',
    ),
    _NavItem(
      icon: Icons.add,
      activeIcon: Icons.add,
      label: '', // FAB central
      route: '/scan',
      isFab: true,
    ),
    _NavItem(
      icon: Icons.lightbulb_outline,
      activeIcon: Icons.lightbulb,
      label: 'Insights',
      route: '/insights',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
      route: '/profile',
    ),
  ];

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    
    HapticService.lightTap();
    
    final item = _navItems[index];
    
    if (item.isFab) {
      // Animation spéciale pour le FAB
      _onScannerPressed();
    } else {
      setState(() => _currentIndex = index);
      context.go(item.route);
    }
  }

  void _onScannerPressed() {
    HapticService.mediumTap();
    
    // Animation de scale sur le FAB
    context.push('/scan');
  }

  @override
  Widget build(BuildContext context) {
    // Déterminer l'index actuel basé sur la route
    final location = GoRouterState.of(context).uri.path;
    _currentIndex = _navItems.indexWhere(
      (item) => location.startsWith(item.route) && !item.isFab,
    );
    if (_currentIndex == -1) _currentIndex = 0;

    return Scaffold(
      body: widget.child,
      extendBody: true, // Permet au contenu d'aller sous la bottom nav
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GlassCard(
        borderRadius: AuraDimensions.radiusXXL,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        blurStrength: 30,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == _currentIndex;
              
              if (item.isFab) {
                return _buildScannerFab();
              }
              
              return _buildNavItem(item, isSelected, index);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AuraColors.auraAmber.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AuraDimensions.radiusM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected
                  ? AuraColors.auraAmber
                  : AuraColors.auraTextDarkSecondary,
              size: 24,
            ),
            if (item.label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected
                      ? AuraColors.auraAmber
                      : AuraColors.auraTextDarkSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScannerFab() {
    return GestureDetector(
      onTap: _onScannerPressed,
      child: Hero(
        tag: 'scanner_fab',
        child: Container(
          width: 64,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AuraColors.auraAmber,
                AuraColors.auraDeep,
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AuraColors.auraAmber.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isFab;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.isFab = false,
  });
}
