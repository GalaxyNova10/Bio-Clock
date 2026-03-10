import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/app_theme.dart';

/// 4-tab navigation: Home, Inventory, [Scan], Graph, Profile.
/// Center tab has an elevated green squircle with scanner icon.
class ScaffoldWithNav extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNav({super.key, required this.child});

  // The 4 "regular" nav items (Scan is the elevated center button).
  static const _destinations = [
    _NavItem(
        icon: LucideIcons.home,
        selectedIcon: LucideIcons.home,
        label: 'Home',
        path: '/'),
    _NavItem(
        icon: LucideIcons.box,
        selectedIcon: LucideIcons.box,
        label: 'Inventory',
        path: '/inventory'),
    // index 2 = Scan — handled as the elevated center button
    _NavItem(
        icon: LucideIcons.lineChart,
        selectedIcon: LucideIcons.lineChart,
        label: 'Graph',
        path: '/graph'),
    _NavItem(
        icon: LucideIcons.user,
        selectedIcon: LucideIcons.user,
        label: 'Profile',
        path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _selectedIndex(location);
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    final isHome = location == '/';

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true, // Key for floating nav
      extendBodyBehindAppBar: isHome, // Smooth status bar transition for Home
      appBar: _buildAppBar(context, isWide, isHome),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Row(
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
                  child: SvgPicture.asset(
                    'assets/images/bioClockLeafLogo.svg',
                    width: 40,
                    height: 40,
                  ),
                ),
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(_destinations[0].icon),
                    selectedIcon: Icon(_destinations[0].selectedIcon),
                    label: Text(_destinations[0].label),
                  ),
                  NavigationRailDestination(
                    icon: Icon(_destinations[1].icon),
                    selectedIcon: Icon(_destinations[1].selectedIcon),
                    label: Text(_destinations[1].label),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(LucideIcons.scan),
                    selectedIcon: Icon(LucideIcons.scan),
                    label: Text('Scan'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(_destinations[2].icon),
                    selectedIcon: Icon(_destinations[2].selectedIcon),
                    label: Text(_destinations[2].label),
                  ),
                  NavigationRailDestination(
                    icon: Icon(_destinations[3].icon),
                    selectedIcon: Icon(_destinations[3].selectedIcon),
                    label: Text(_destinations[3].label),
                  ),
                ],
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isWide ? 0 : 100),
                child: child,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isWide ? null : _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar:
          isWide ? null : _buildBottomAppBar(context, selected),
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context, bool isWide, bool isHome) {
    if (isWide) return null; // Don't show app bar on wide screens
    if (isHome) return null; // Home has its own SliverAppBar
    
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/images/bioClockLeafLogo.svg',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text('Bio Clock',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
      actions: [
        // AI Engine Status Badge moved to AppBar
        Center(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.emeraldCore.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.emeraldCore.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.emeraldCore,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "Amazon Nova Pro",
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.emeraldCore,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFab(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppTheme.emeraldBrite, AppTheme.emeraldCore],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          // Premium shadow layering
          BoxShadow(
            color: AppTheme.emeraldCore.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          // Inner highlight for depth
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => context.go('/scan'),
          customBorder: const CircleBorder(),
          child: const Center(
            child: Icon(LucideIcons.scan, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar(BuildContext context, int selected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.surfaceUp
              : const Color(0xFF1E293B).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(32.0),
          boxShadow: isDark
              ? AppTheme.clayShadow
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    spreadRadius: -2,
                    offset: const Offset(0, 3),
                  ),
                ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.06),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: BottomAppBar(
          color: Colors.transparent, // Container provides the background
          shape: const CircularNotchedRectangle(),
          notchMargin: 10.0,
          elevation: 0,
          height: 68.0,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                  child:
                      _navButton(context, 0, selected, _destinations[0])),
              Expanded(
                  child:
                      _navButton(context, 1, selected, _destinations[1])),
              SizedBox(
                width: 64.0,
                child: GestureDetector(
                  onTap: () => context.go('/scan'),
                  behavior: HitTestBehavior.opaque,
                  child: Transform.translate(
                    offset: const Offset(0, 12),
                    child: Text(
                      'Scan',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: selected == 2
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selected == 2
                            ? AppTheme.emeraldCore
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                  child:
                      _navButton(context, 3, selected, _destinations[2])),
              Expanded(
                  child:
                      _navButton(context, 4, selected, _destinations[3])),
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
      2 => 2, // Scan
      3 => 3, // Graph
      4 => 4, // Profile
      _ => 0,
    };
  }

  void _navigateRail(BuildContext context, int railIndex) {
    final path = switch (railIndex) {
      0 => '/',
      1 => '/inventory',
      2 => '/scan',
      3 => '/graph',
      4 => '/profile',
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
