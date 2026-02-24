// 바텀 네비게이션 스캐폴드 - 앱 셸 레이아웃
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  // 바텀 네비게이션 탭 정보
  static const List<_NavItem> _items = [
    _NavItem(
      label: '홈',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: '운동',
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
    ),
    _NavItem(
      label: '커뮤니티',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
    ),
    _NavItem(
      label: '식단',
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant,
    ),
    _NavItem(
      label: '캘린더',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
    ),
  ];

  void _onTabTapped(BuildContext context, int index) {
    // 같은 탭을 눌렀을 때는 해당 탭의 루트로 이동
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          items: _items
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// 바텀 네비게이션 아이템 데이터 클래스
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
