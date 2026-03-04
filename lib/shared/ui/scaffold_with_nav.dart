import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';

/// 4-tab navigation: Home, Inventory, [Scan], Graph, Profile.
/// Center tab has an elevated green squircle with scanner icon.
class ScaffoldWithNav extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNav({super.key, required this.child});

  // The 4 "regular" nav items (Scan is the elevated center button).
  static const _destinations = [
    _NavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
        path: '/'),
    _NavItem(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        label: 'Vault',
        path: '/inventory'),
    // index 2 = Scan — handled as the elevated center button
    _NavItem(
        icon: Icons.show_chart_outlined,
        selectedIcon: Icons.show_chart,
        label: 'Graph',
        path: '/graph'),
    _NavItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Profile',
        path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _selectedIndex(location);
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    const bgColor = AppTheme.bgDeep;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true, // Key for floating nav
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              backgroundColor: bgColor,
              selectedIndex: _railIndex(selected),
              onDestinationSelected: (i) => _navigateRail(context, i),
              labelType: NavigationRailLabelType.selected,
              indicatorColor: AppTheme.emeraldCore.withValues(alpha: 0.12),
              selectedIconTheme:
                  const IconThemeData(color: AppTheme.emeraldCore),
              selectedLabelTextStyle: GoogleFonts.nunito(
                color: AppTheme.emeraldCore,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedIconTheme: const IconThemeData(
                color: AppTheme.textMuted,
              ),
              unselectedLabelTextStyle: GoogleFonts.nunito(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
              leading: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldCore,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.eco, color: AppTheme.bgDeep, size: 22),
                ),
              ),
              destinations: [
                ..._destinations.map((d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    )),
                const NavigationRailDestination(
                  icon: Icon(Icons.qr_code_scanner_outlined),
                  selectedIcon: Icon(Icons.qr_code_scanner),
                  label: Text('Scan'),
                ),
              ],
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar:
          isWide ? null : _buildFloatingBottomNav(context, selected),
    );
  }

  Widget _buildFloatingBottomNav(BuildContext context, int selected) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.surfaceUp, // Stadium pill background
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            boxShadow: AppTheme.clayShadow,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navButton(context, 0, selected, _destinations[0]), // Home
                  _navButton(context, 1, selected, _destinations[1]), // Vault
                  const SizedBox(width: 80), // Space for center scan button
                  _navButton(context, 3, selected, _destinations[2]), // Graph
                  _navButton(context, 4, selected, _destinations[3]), // Profile
                ],
              ),

              // Center elevated scan button - squircle
              Positioned(
                top: -24,
                child: GestureDetector(
                  onTap: () => context.go('/scan'),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20), // Squircle
                      gradient: const LinearGradient(
                        colors: [AppTheme.emeraldBrite, AppTheme.emeraldCore],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: AppTheme.clayGlowShadow,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: const Icon(Icons.qr_code_scanner,
                        color: AppTheme.bgDeep, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton(
      BuildContext context, int index, int selected, _NavItem item) {
    final isSelected = selected == index;

    return GestureDetector(
      onTap: () => context.go(item.path),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? item.selectedIcon : item.icon,
            size: 24,
            color: isSelected ? AppTheme.emeraldCore : AppTheme.textMuted,
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? AppTheme.emeraldCore : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location == '/') return 0;
    if (location.startsWith('/inventory')) return 1;
    if (location.startsWith('/scan')) return 2;
    if (location.startsWith('/graph')) return 3;
    if (location.startsWith('/profile') ||
        location.startsWith('/settings') ||
        location.startsWith('/about') ||
        location.startsWith('/pitch')) {
      return 4;
    }
    return 0;
  }

  int _railIndex(int visualIndex) {
    return switch (visualIndex) {
      0 => 0, // Home
      1 => 1, // Inventory
      2 => 4, // Scan → last rail item
      3 => 2, // Graph
      4 => 3, // Profile
      _ => 0,
    };
  }

  void _navigateRail(BuildContext context, int railIndex) {
    final path = switch (railIndex) {
      0 => '/',
      1 => '/inventory',
      2 => '/graph',
      3 => '/profile',
      4 => '/scan',
      _ => '/',
    };
    context.go(path);
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.path,
  });
}
