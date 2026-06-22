import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/providers/selected_station_provider.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});
  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/admin/dashboard')) return 0;
    if (loc.startsWith('/admin/complaints')) return 1;
    if (loc.startsWith('/admin/stations')) return 2;
    if (loc.startsWith('/admin/users')) return 3;
    if (loc.startsWith('/admin/officers')) return 4;
    if (loc.startsWith('/admin/profile')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _index(context);
    final selectedStation = ref.watch(selectedStationProvider);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedStation != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7B1FA2).withValues(alpha: 0.15),
                      const Color(0xFF1565C0).withValues(alpha: 0.15),
                    ],
                  ),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_police_rounded,
                        size: 13, color: AppColors.primaryLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Viewing: ${selectedStation.name}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref
                          .read(selectedStationProvider.notifier)
                          .state = null,
                      child: const Text('Clear',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            NavigationBar(
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primary.withValues(alpha: 0.15),
              selectedIndex: idx,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    context.go('/admin/dashboard');
                    break;
                  case 1:
                    context.go('/admin/complaints');
                    break;
                  case 2:
                    context.go('/admin/stations');
                    break;
                  case 3:
                    context.go('/admin/users');
                    break;
                  case 4:
                    context.go('/admin/officers');
                    break;
                  case 5:
                    context.go('/admin/profile');
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon:
                      Icon(Icons.dashboard_outlined, color: AppColors.textHint),
                  selectedIcon: Icon(Icons.dashboard_rounded,
                      color: AppColors.primaryLight),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined, color: AppColors.textHint),
                  selectedIcon:
                      Icon(Icons.folder_rounded, color: AppColors.primaryLight),
                  label: 'Cases',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_outlined,
                      color: AppColors.textHint),
                  selectedIcon: Icon(Icons.account_balance_rounded,
                      color: AppColors.primaryLight),
                  label: 'Stations',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline, color: AppColors.textHint),
                  selectedIcon:
                      Icon(Icons.people_rounded, color: AppColors.primaryLight),
                  label: 'Users',
                ),
                NavigationDestination(
                  icon: Icon(Icons.badge_outlined, color: AppColors.textHint),
                  selectedIcon:
                      Icon(Icons.badge_rounded, color: AppColors.primaryLight),
                  label: 'Officers',
                ),
                NavigationDestination(
                  icon: Icon(Icons.admin_panel_settings_outlined,
                      color: AppColors.textHint),
                  selectedIcon: Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.primaryLight),
                  label: 'Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
