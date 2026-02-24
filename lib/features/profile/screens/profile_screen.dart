import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Local models
// ---------------------------------------------------------------------------

class UserProfile {
  final String name;
  final String joinDate;
  final int totalWorkoutDays;
  final int currentStreak;
  final double totalVolume;
  final double currentWeight;
  final double targetWeight;
  final String avatarInitials;
  final Color avatarColor;

  const UserProfile({
    required this.name,
    required this.joinDate,
    required this.totalWorkoutDays,
    required this.currentStreak,
    required this.totalVolume,
    required this.currentWeight,
    required this.targetWeight,
    required this.avatarInitials,
    required this.avatarColor,
  });
}

class WeightEntry {
  final DateTime date;
  final double weight;

  const WeightEntry({required this.date, required this.weight});
}

class BeforeAfterPhoto {
  final String label;
  final Color color;
  final IconData icon;

  const BeforeAfterPhoto({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class SettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final bool showArrow;

  const SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.showArrow = true,
  });
}

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

const _profile = UserProfile(
  name: '최주용',
  joinDate: '2024년 3월 1일',
  totalWorkoutDays: 87,
  currentStreak: 14,
  totalVolume: 284560,
  currentWeight: 75.5,
  targetWeight: 70.0,
  avatarInitials: '주',
  avatarColor: Colors.blue,
);

final List<WeightEntry> _weightHistory = () {
  final now = DateTime.now();
  final weights = [
    82.0, 81.2, 80.5, 80.0, 79.3, 78.8, 78.5,
    78.0, 77.4, 76.8, 76.5, 76.0, 75.8, 75.5,
  ];
  return weights.asMap().entries.map((e) {
    return WeightEntry(
      date: now.subtract(Duration(days: (weights.length - 1 - e.key) * 7)),
      weight: e.value,
    );
  }).toList();
}();

const _beforeAfterPhotos = [
  BeforeAfterPhoto(
    label: 'Before',
    color: Colors.red,
    icon: Icons.camera_alt_outlined,
  ),
  BeforeAfterPhoto(
    label: 'After',
    color: Colors.green,
    icon: Icons.camera_alt,
  ),
];

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final profileProvider = StateProvider<UserProfile>((ref) => _profile);

// ---------------------------------------------------------------------------
// ProfileScreen
// ---------------------------------------------------------------------------

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile App Bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(profile: profile, l10n: l10n),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats
                  _StatsSection(profile: profile, l10n: l10n),
                  const SizedBox(height: 20),

                  // Weight chart
                  _WeightChartSection(
                    history: _weightHistory,
                    profile: profile,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 20),

                  // Before/After
                  _BeforeAfterSection(l10n: l10n),
                  const SizedBox(height: 20),

                  // Settings
                  _SettingsSection(l10n: l10n),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile Header
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final AppLocalizations l10n;
  const _ProfileHeader({required this.profile, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      profile.avatarInitials,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                l10n.startedWorkoutOn(profile.joinDate),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats Section
// ---------------------------------------------------------------------------

class _StatsSection extends StatelessWidget {
  final UserProfile profile;
  final AppLocalizations l10n;
  const _StatsSection({required this.profile, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.myRecord,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today,
                label: l10n.totalWorkoutDays,
                value: '${profile.totalWorkoutDays}${l10n.days}',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                label: l10n.consecutiveStreak,
                value: '${profile.currentStreak}${l10n.days}',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.fitness_center,
                label: l10n.totalVolumeKg,
                value: _formatVolume(profile.totalVolume),
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}t';
    }
    return '${volume.toStringAsFixed(0)}kg';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weight Chart Section
// ---------------------------------------------------------------------------

class _WeightChartSection extends StatelessWidget {
  final List<WeightEntry> history;
  final UserProfile profile;
  final AppLocalizations l10n;

  const _WeightChartSection({
    required this.history,
    required this.profile,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final minY = history.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = history.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.weightChange,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${l10n.goal}: ${profile.targetWeight} ${l10n.kg}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
            child: SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: profile.targetWeight,
                        color: Colors.green.withValues(alpha: 0.6),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                          ),
                          labelResolver: (_) =>
                              '${l10n.goal} ${profile.targetWeight}${l10n.kg}',
                        ),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${l10n.currentWeight}: ${profile.currentWeight} ${l10n.kg}',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${l10n.weightChange}: ${(history.first.weight - profile.currentWeight).toStringAsFixed(1)} ${l10n.kg}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Before/After Section
// ---------------------------------------------------------------------------

class _BeforeAfterSection extends StatelessWidget {
  final AppLocalizations l10n;
  const _BeforeAfterSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.beforeAfterPhoto,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              l10n.addPhoto,
              style: const TextStyle(color: Colors.blue, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: _beforeAfterPhotos.map((photo) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                height: 160,
                decoration: BoxDecoration(
                  color: photo.color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: photo.color.withValues(alpha: 0.25),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      photo.icon,
                      size: 36,
                      color: photo.color.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      photo.label,
                      style: TextStyle(
                        color: photo.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tapToAdd,
                      style: TextStyle(
                        color: photo.color.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Settings Section
// ---------------------------------------------------------------------------

class _SettingsSection extends StatelessWidget {
  final AppLocalizations l10n;
  const _SettingsSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final settingItems = _buildSettingItems(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settings,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: settingItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isLast = i == settingItems.length - 1;

              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: (item.iconColor ?? Colors.grey)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.iconColor ?? Colors.grey,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: item.title == l10n.logout
                            ? Colors.red
                            : null,
                      ),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(
                            item.subtitle!,
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    trailing: item.showArrow
                        ? const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          )
                        : null,
                    onTap: () {},
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<SettingItem> _buildSettingItems(AppLocalizations l10n) {
    return [
      SettingItem(
        icon: Icons.person_outline,
        title: l10n.personalInfoEdit,
        iconColor: Colors.blue,
      ),
      SettingItem(
        icon: Icons.monitor_weight_outlined,
        title: l10n.targetWeightSetting,
        subtitle: '70.0 ${l10n.kg}',
        iconColor: Colors.purple,
      ),
      SettingItem(
        icon: Icons.notifications_outlined,
        title: l10n.notificationSettings,
        iconColor: Colors.orange,
      ),
      SettingItem(
        icon: Icons.bar_chart,
        title: l10n.workoutStatsMenu,
        iconColor: Colors.green,
      ),
      SettingItem(
        icon: Icons.share_outlined,
        title: l10n.shareWithFriends,
        iconColor: Colors.teal,
      ),
      SettingItem(
        icon: Icons.privacy_tip_outlined,
        title: l10n.privacyPolicy,
        iconColor: Colors.grey,
      ),
      SettingItem(
        icon: Icons.help_outline,
        title: l10n.helpAndSupport,
        iconColor: Colors.grey,
      ),
      SettingItem(
        icon: Icons.logout,
        title: l10n.logout,
        iconColor: Colors.red,
        showArrow: false,
      ),
    ];
  }
}
