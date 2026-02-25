// 바텀 네비게이션 스캐폴드 - 앱 셸 레이아웃
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:health_app/l10n/app_localizations.dart';

/// 앱 전체의 셸 스캐폴드 위젯
/// StatefulShellRoute.indexedStack과 함께 사용되어 탭 상태를 유지합니다.
class BottomNavScaffold extends StatelessWidget {
  /// go_router가 제공하는 현재 선택된 탭 인덱스
  final int currentIndex;

  /// go_router가 제공하는 탭별 네비게이터
  final StatefulNavigationShell navigationShell;

  const BottomNavScaffold({
    super.key,
    required this.currentIndex,
    required this.navigationShell,
  });

  // 바텀 네비게이션 탭 아이콘 정보
  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
    ),
    _NavItem(
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
    ),
    _NavItem(
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant,
    ),
    _NavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
    ),
  ];

  // l10n 기반 탭 라벨 목록
  List<String> _labels(AppLocalizations l10n) => [
        l10n.navHome,
        l10n.navWorkout,
        l10n.navCommunity,
        l10n.navDiet,
        l10n.navCalendar,
      ];

  void _onTabTapped(BuildContext context, int index) {
    if (index == navigationShell.currentIndex) {
      // 같은 탭을 다시 눌렀을 때: 스크롤 최상단으로 이동 (표준 모바일 UX)
      // PrimaryScrollController는 각 탭의 주 ListView/CustomScrollView에
      // Flutter가 자동으로 연결하므로 별도 ScrollController 없이 작동합니다.
      final scrollController = PrimaryScrollController.maybeOf(context);
      if (scrollController != null && scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        return;
      }
    }
    // 다른 탭이거나 스크롤 컨트롤러 없을 때: 탭 전환
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final labels = _labels(l10n);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onTabTapped(context, index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: colorScheme.surface,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items: List.generate(
            _items.length,
            (i) => BottomNavigationBarItem(
              icon: Icon(_items[i].icon),
              activeIcon: Icon(_items[i].activeIcon),
              label: labels[i],
            ),
          ),
        ),
      ),
    );
  }
}

/// 바텀 네비게이션 아이템 데이터 클래스
class _NavItem {
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
  });
}
