// 바디 프로그레스 사진 비교 화면 – Before/After 사진 기록 및 비교
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:health_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum BodyPoseType {
  front,
  side,
  back;

  String get label {
    switch (this) {
      case BodyPoseType.front:
        return '앞모습';
      case BodyPoseType.side:
        return '옆모습';
      case BodyPoseType.back:
        return '뒷모습';
    }
  }

  IconData get icon {
    switch (this) {
      case BodyPoseType.front:
        return Icons.accessibility_new;
      case BodyPoseType.side:
        return Icons.switch_left;
      case BodyPoseType.back:
        return Icons.accessibility;
    }
  }
}

class BodyProgressEntry {
  final String id;
  final String imagePath;
  final DateTime date;
  final double? weight;
  final double? bodyFatPercent;
  final String? note;
  final BodyPoseType pose;

  const BodyProgressEntry({
    required this.id,
    required this.imagePath,
    required this.date,
    this.weight,
    this.bodyFatPercent,
    this.note,
    required this.pose,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'date': date.toIso8601String(),
        'weight': weight,
        'bodyFatPercent': bodyFatPercent,
        'note': note,
        'pose': pose.index,
      };

  factory BodyProgressEntry.fromJson(Map<String, dynamic> json) =>
      BodyProgressEntry(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        date: DateTime.parse(json['date'] as String),
        weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
        bodyFatPercent: json['bodyFatPercent'] != null
            ? (json['bodyFatPercent'] as num).toDouble()
            : null,
        note: json['note'] as String?,
        pose: BodyPoseType.values[json['pose'] as int],
      );
}

// ---------------------------------------------------------------------------
// State Notifier
// ---------------------------------------------------------------------------

class BodyProgressNotifier extends StateNotifier<List<BodyProgressEntry>> {
  static const _prefsKey = 'body_progress_entries';

  BodyProgressNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    final entries = <BodyProgressEntry>[];
    for (final s in raw) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        entries.add(BodyProgressEntry.fromJson(map));
      } catch (_) {
        // skip corrupt entries
      }
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    state = entries;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_prefsKey, raw);
  }

  Future<void> addEntry(BodyProgressEntry entry) async {
    final updated = [entry, ...state];
    updated.sort((a, b) => b.date.compareTo(a.date));
    state = updated;
    await _save();
  }

  Future<void> removeEntry(String id) async {
    // Remove the image file too
    final entry = state.firstWhere((e) => e.id == id, orElse: () => throw StateError('not found'));
    try {
      final file = File(entry.imagePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}

    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  Map<String, List<BodyProgressEntry>> groupByMonth() {
    final map = <String, List<BodyProgressEntry>>{};
    for (final e in state) {
      final key = DateFormat('yyyy년 MM월').format(e.date);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final bodyProgressProvider =
    StateNotifierProvider<BodyProgressNotifier, List<BodyProgressEntry>>(
  (_) => BodyProgressNotifier(),
);

// ---------------------------------------------------------------------------
// BodyProgressScreen
// ---------------------------------------------------------------------------

class BodyProgressScreen extends ConsumerStatefulWidget {
  const BodyProgressScreen({super.key});

  @override
  ConsumerState<BodyProgressScreen> createState() =>
      _BodyProgressScreenState();
}

class _BodyProgressScreenState extends ConsumerState<BodyProgressScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  // indices of selected entries for Before/After comparison
  String? _beforeId;
  String? _afterId;
  // Overlay slider position (0.0 = full before, 1.0 = full after)
  double _sliderValue = 0.5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(bodyProgressProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.bodyProgress),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withValues(alpha: 0.6),
          indicatorColor: colorScheme.onPrimary,
          tabs: [
            Tab(text: l10n.photoGallery),
            Tab(text: l10n.beforeAfter),
            Tab(text: l10n.timeline),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PhotoGridTab(entries: entries),
          _CompareTab(
            entries: entries,
            beforeId: _beforeId,
            afterId: _afterId,
            sliderValue: _sliderValue,
            onBeforeChanged: (id) => setState(() => _beforeId = id),
            onAfterChanged: (id) => setState(() => _afterId = id),
            onSliderChanged: (v) => setState(() => _sliderValue = v),
          ),
          _TimelineTab(entries: entries),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPhotoSheet(context),
        tooltip: l10n.addProgressPhoto,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Future<void> _showAddPhotoSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddPhotoSheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1: Photo Grid Tab
// ---------------------------------------------------------------------------

class _PhotoGridTab extends ConsumerWidget {
  final List<BodyProgressEntry> entries;

  const _PhotoGridTab({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return _EmptyState(
        onAdd: () => _openAddSheet(context),
      );
    }

    final notifier = ref.read(bodyProgressProvider.notifier);
    final grouped = notifier.groupByMonth();
    final months = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: months.length,
      itemBuilder: (context, index) {
        final month = months[index];
        final monthEntries = grouped[month]!;
        return _MonthGroup(
          month: month,
          entries: monthEntries,
        );
      },
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddPhotoSheet(),
    );
  }
}

class _MonthGroup extends StatelessWidget {
  final String month;
  final List<BodyProgressEntry> entries;

  const _MonthGroup({required this.month, required this.entries});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            month,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 0.75,
          ),
          itemCount: entries.length,
          itemBuilder: (context, i) => _PhotoThumbnail(entry: entries[i]),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PhotoThumbnail extends ConsumerWidget {
  final BodyProgressEntry entry;

  const _PhotoThumbnail({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showDetail(context),
      onLongPress: () => _confirmDelete(context, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            _buildImage(),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Bottom info
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entry.weight != null)
                    Text(
                      '${entry.weight!.toStringAsFixed(1)}kg',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    DateFormat('MM/dd').format(entry.date),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            // Pose badge
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.pose.label,
                  style: TextStyle(
                    fontSize: 9,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final file = File(entry.imagePath);
    return file.existsSync()
        ? Image.file(file, fit: BoxFit.cover)
        : Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
  }

  void _showDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PhotoDetailScreen(entry: entry),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePhoto),
        content: Text(l10n.deletePhotoConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(bodyProgressProvider.notifier).removeEntry(entry.id);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo Detail Screen
// ---------------------------------------------------------------------------

class _PhotoDetailScreen extends StatelessWidget {
  final BodyProgressEntry entry;

  const _PhotoDetailScreen({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final file = File(entry.imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          DateFormat('yyyy년 MM월 dd일').format(entry.date),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: file.existsSync()
                ? InteractiveViewer(
                    child: Image.file(file, fit: BoxFit.contain),
                  )
                : const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey, size: 64),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(icon: Icons.accessibility_new, label: l10n.poseLabel, value: _localizedPoseLabel(l10n, entry.pose)),
                if (entry.weight != null)
                  _DetailRow(
                    icon: Icons.monitor_weight_outlined,
                    label: l10n.bodyWeightLabel,
                    value: '${entry.weight!.toStringAsFixed(1)} ${l10n.kg}',
                  ),
                if (entry.bodyFatPercent != null)
                  _DetailRow(
                    icon: Icons.water_drop_outlined,
                    label: l10n.bodyFatLabel,
                    value: '${entry.bodyFatPercent!.toStringAsFixed(1)} %',
                  ),
                if (entry.note != null && entry.note!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.notes,
                    label: l10n.memoLabel,
                    value: entry.note!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2: Before/After Compare Tab
// ---------------------------------------------------------------------------

class _CompareTab extends StatelessWidget {
  final List<BodyProgressEntry> entries;
  final String? beforeId;
  final String? afterId;
  final double sliderValue;
  final ValueChanged<String?> onBeforeChanged;
  final ValueChanged<String?> onAfterChanged;
  final ValueChanged<double> onSliderChanged;

  const _CompareTab({
    required this.entries,
    required this.beforeId,
    required this.afterId,
    required this.sliderValue,
    required this.onBeforeChanged,
    required this.onAfterChanged,
    required this.onSliderChanged,
  });

  BodyProgressEntry? _entryById(String? id) =>
      id == null ? null : entries.cast<BodyProgressEntry?>().firstWhere(
            (e) => e?.id == id,
            orElse: () => null,
          );

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyState(
        onAdd: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _AddPhotoSheet(),
        ),
      );
    }

    final beforeEntry = _entryById(beforeId);
    final afterEntry = _entryById(afterId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date pickers
          _DatePickerRow(
            entries: entries,
            beforeId: beforeId,
            afterId: afterId,
            onBeforeChanged: onBeforeChanged,
            onAfterChanged: onAfterChanged,
          ),
          const SizedBox(height: 16),

          // Comparison view
          if (beforeEntry != null && afterEntry != null) ...[
            _OverlayCompareView(
              beforeEntry: beforeEntry,
              afterEntry: afterEntry,
              sliderValue: sliderValue,
              onSliderChanged: onSliderChanged,
            ),
            const SizedBox(height: 16),
            _StatsDiffCard(before: beforeEntry, after: afterEntry),
          ] else ...[
            _SideBySideView(
              beforeEntry: beforeEntry,
              afterEntry: afterEntry,
            ),
          ],
        ],
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final List<BodyProgressEntry> entries;
  final String? beforeId;
  final String? afterId;
  final ValueChanged<String?> onBeforeChanged;
  final ValueChanged<String?> onAfterChanged;

  const _DatePickerRow({
    required this.entries,
    required this.beforeId,
    required this.afterId,
    required this.onBeforeChanged,
    required this.onAfterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PhotoSelector(
            label: 'Before',
            selectedId: beforeId,
            entries: entries,
            accentColor: Colors.red,
            onChanged: onBeforeChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PhotoSelector(
            label: 'After',
            selectedId: afterId,
            entries: entries,
            accentColor: Colors.green,
            onChanged: onAfterChanged,
          ),
        ),
      ],
    );
  }
}

class _PhotoSelector extends StatelessWidget {
  final String label;
  final String? selectedId;
  final List<BodyProgressEntry> entries;
  final Color accentColor;
  final ValueChanged<String?> onChanged;

  const _PhotoSelector({
    required this.label,
    required this.selectedId,
    required this.entries,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected =
        selectedId == null ? null : entries.cast<BodyProgressEntry?>().firstWhere(
              (e) => e?.id == selectedId,
              orElse: () => null,
            );

    final l10n = AppLocalizations.of(context);
    final displayText = selected != null
        ? DateFormat('yy.MM.dd').format(selected.date)
        : l10n.selectDate;

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              displayText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: accentColor),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _EntryPickerSheet(
        entries: entries,
        selectedId: selectedId,
        label: label,
        accentColor: accentColor,
        onSelected: (id) {
          onChanged(id);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _EntryPickerSheet extends StatelessWidget {
  final List<BodyProgressEntry> entries;
  final String? selectedId;
  final String label;
  final Color accentColor;
  final ValueChanged<String> onSelected;

  const _EntryPickerSheet({
    required this.entries,
    required this.selectedId,
    required this.label,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '$label ${l10n.selectPose}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 280,
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (ctx, i) {
                final e = entries[i];
                final isSelected = e.id == selectedId;
                return ListTile(
                  selected: isSelected,
                  selectedColor: accentColor,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: File(e.imagePath).existsSync()
                          ? Image.file(File(e.imagePath), fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.photo, color: Colors.grey, size: 18),
                            ),
                    ),
                  ),
                  title: Text(DateFormat('yyyy년 MM월 dd일').format(e.date)),
                  subtitle: Text(
                    [
                      e.pose.label,
                      if (e.weight != null) '${e.weight!.toStringAsFixed(1)}kg',
                    ].join(' · '),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: accentColor)
                      : null,
                  onTap: () => onSelected(e.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Overlay slider comparison view
class _OverlayCompareView extends StatelessWidget {
  final BodyProgressEntry beforeEntry;
  final BodyProgressEntry afterEntry;
  final double sliderValue;
  final ValueChanged<double> onSliderChanged;

  const _OverlayCompareView({
    required this.beforeEntry,
    required this.afterEntry,
    required this.sliderValue,
    required this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const height = 380.0;
    final beforeFile = File(beforeEntry.imagePath);
    final afterFile = File(afterEntry.imagePath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.overlayCompare,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            const Icon(Icons.swipe, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              l10n.slideToCompare,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              // Image overlay area
              SizedBox(
                height: height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final dividerX = totalWidth * sliderValue;

                    return Stack(
                      children: [
                        // After image (background - full width)
                        Positioned.fill(
                          child: afterFile.existsSync()
                              ? Image.file(afterFile, fit: BoxFit.cover)
                              : _PlaceholderImage(label: 'After', color: Colors.green),
                        ),
                        // Before image (clipped to left portion)
                        Positioned.fill(
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: sliderValue,
                              child: SizedBox(
                                width: totalWidth,
                                height: height,
                                child: beforeFile.existsSync()
                                    ? Image.file(beforeFile, fit: BoxFit.cover)
                                    : _PlaceholderImage(label: 'Before', color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                        // Divider line
                        Positioned(
                          left: dividerX - 1.5,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            color: Colors.white,
                          ),
                        ),
                        // Drag handle
                        Positioned(
                          left: dividerX - 18,
                          top: height / 2 - 18,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.compare_arrows, size: 20, color: Colors.grey),
                          ),
                        ),
                        // Labels
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _OverlayBadge(label: 'Before', color: Colors.red),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _OverlayBadge(label: 'After', color: Colors.green),
                        ),
                        // GestureDetector on top for slide interaction
                        Positioned.fill(
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              final newVal = (sliderValue + details.delta.dx / totalWidth)
                                  .clamp(0.0, 1.0);
                              onSliderChanged(newVal);
                            },
                            onTapDown: (details) {
                              final newVal = (details.localPosition.dx / totalWidth)
                                  .clamp(0.0, 1.0);
                              onSliderChanged(newVal);
                            },
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    const Text(
                      'Before',
                      style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Slider(
                        value: sliderValue,
                        onChanged: onSliderChanged,
                        activeColor: Colors.green,
                        inactiveColor: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    const Text(
                      'After',
                      style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverlayBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _OverlayBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Side by side view (when only one or neither photo selected)
class _SideBySideView extends StatelessWidget {
  final BodyProgressEntry? beforeEntry;
  final BodyProgressEntry? afterEntry;

  const _SideBySideView({this.beforeEntry, this.afterEntry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Row(
        children: [
          Expanded(
            child: _PhotoSlot(
              label: 'Before',
              entry: beforeEntry,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PhotoSlot(
              label: 'After',
              entry: afterEntry,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final String label;
  final BodyProgressEntry? entry;
  final Color color;

  const _PhotoSlot({
    required this.label,
    required this.entry,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: color.withValues(alpha: 0.5), size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).selectAbove,
              style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final file = File(entry!.imagePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          file.existsSync()
              ? Image.file(file, fit: BoxFit.cover)
              : _PlaceholderImage(label: label, color: color),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: _OverlayBadge(label: label, color: color),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('yyyy.MM.dd').format(entry!.date),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                if (entry!.weight != null)
                  Text(
                    '${entry!.weight!.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Stats difference card
class _StatsDiffCard extends StatelessWidget {
  final BodyProgressEntry before;
  final BodyProgressEntry after;

  const _StatsDiffCard({required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final weightDiff = (after.weight != null && before.weight != null)
        ? after.weight! - before.weight!
        : null;
    final fatDiff = (after.bodyFatPercent != null && before.bodyFatPercent != null)
        ? after.bodyFatPercent! - before.bodyFatPercent!
        : null;
    final daysDiff = after.date.difference(before.date).inDays.abs();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.changeSummary,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DiffTile(
                    icon: Icons.calendar_today,
                    label: l10n.duration,
                    value: l10n.daysCount(daysDiff),
                    color: colorScheme.primary,
                  ),
                ),
                if (weightDiff != null)
                  Expanded(
                    child: _DiffTile(
                      icon: Icons.monitor_weight_outlined,
                      label: l10n.weightChange,
                      value:
                          '${weightDiff >= 0 ? '+' : ''}${weightDiff.toStringAsFixed(1)} kg',
                      color: weightDiff <= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                if (fatDiff != null)
                  Expanded(
                    child: _DiffTile(
                      icon: Icons.water_drop_outlined,
                      label: l10n.bodyFatChange,
                      value:
                          '${fatDiff >= 0 ? '+' : ''}${fatDiff.toStringAsFixed(1)} %',
                      color: fatDiff <= 0 ? Colors.green : Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DiffTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section 3: Timeline Tab
// ---------------------------------------------------------------------------

class _TimelineTab extends StatelessWidget {
  final List<BodyProgressEntry> entries;

  const _TimelineTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyState(
        onAdd: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _AddPhotoSheet(),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;
        return _TimelineItem(
          entry: entry,
          isFirst: index == 0,
          isLast: isLast,
          primaryColor: colorScheme.primary,
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final BodyProgressEntry entry;
  final bool isFirst;
  final bool isLast;
  final Color primaryColor;

  const _TimelineItem({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(entry.imagePath);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 32,
            child: CustomPaint(
              painter: _TimelinePainter(
                color: primaryColor,
                isFirst: isFirst,
                isLast: isLast,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: file.existsSync()
                            ? Image.file(file, fit: BoxFit.cover)
                            : _PlaceholderImage(label: entry.pose.label, color: primaryColor),
                      ),
                    ),
                    // Info
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                DateFormat('yyyy년 MM월 dd일').format(entry.date),
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(entry.pose.icon, size: 13, color: primaryColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      entry.pose.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (entry.weight != null || entry.bodyFatPercent != null) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (entry.weight != null)
                                  _InfoChip(
                                    icon: Icons.monitor_weight_outlined,
                                    label: '${entry.weight!.toStringAsFixed(1)} kg',
                                    color: Colors.blue,
                                  ),
                                if (entry.bodyFatPercent != null)
                                  _InfoChip(
                                    icon: Icons.water_drop_outlined,
                                    label: '${entry.bodyFatPercent!.toStringAsFixed(1)} %',
                                    color: Colors.orange,
                                  ),
                              ],
                            ),
                          ],
                          if (entry.note != null && entry.note!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              entry.note!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// Custom painter for timeline line + dot
class _TimelinePainter extends CustomPainter {
  final Color color;
  final bool isFirst;
  final bool isLast;

  const _TimelinePainter({
    required this.color,
    required this.isFirst,
    required this.isLast,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dotRadius = 7.0;
    final dotCenterX = size.width / 2;
    final dotCenterY = 24.0;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Line above dot
    if (!isFirst) {
      canvas.drawLine(
        Offset(dotCenterX, 0),
        Offset(dotCenterX, dotCenterY - dotRadius),
        linePaint,
      );
    }

    // Line below dot
    if (!isLast) {
      canvas.drawLine(
        Offset(dotCenterX, dotCenterY + dotRadius),
        Offset(dotCenterX, size.height),
        linePaint,
      );
    }

    // Dot
    canvas.drawCircle(Offset(dotCenterX, dotCenterY), dotRadius, dotPaint);
    canvas.drawCircle(Offset(dotCenterX, dotCenterY), dotRadius, dotBorderPaint);
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isFirst != isFirst ||
      oldDelegate.isLast != isLast;
}

// ---------------------------------------------------------------------------
// Section 3: Add Photo Bottom Sheet
// ---------------------------------------------------------------------------

class _AddPhotoSheet extends ConsumerStatefulWidget {
  const _AddPhotoSheet();

  @override
  ConsumerState<_AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends ConsumerState<_AddPhotoSheet> {
  XFile? _pickedFile;
  BodyPoseType _selectedPose = BodyPoseType.front;
  final _weightController = TextEditingController();
  final _fatController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _fatController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.addProgressPhoto,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Image picker area
            _ImagePickerArea(
              pickedFile: _pickedFile,
              onPickCamera: () => _pickImage(ImageSource.camera),
              onPickGallery: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 20),

            // Pose guide
            Text(
              l10n.selectPose,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _PoseSelector(
              selectedPose: _selectedPose,
              onChanged: (pose) => setState(() => _selectedPose = pose),
            ),
            const SizedBox(height: 20),

            // Weight input
            Text(
              l10n.weightOptional,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '예: 75.5',
                suffixText: l10n.kg,
              ),
            ),
            const SizedBox(height: 16),

            // Body fat input
            Text(
              l10n.bodyFatOptional,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '예: 18.5',
                suffixText: '%',
              ),
            ),
            const SizedBox(height: 16),

            // Note input
            Text(
              l10n.memoOptional,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.conditionHint,
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickedFile == null || _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? l10n.saving : l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (file != null) {
      setState(() => _pickedFile = file);
    }
  }

  Future<void> _save() async {
    if (_pickedFile == null) return;

    setState(() => _isSaving = true);

    try {
      // Copy image to app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final progressDir = Directory('${dir.path}/body_progress');
      if (!progressDir.existsSync()) {
        progressDir.createSync(recursive: true);
      }

      final id = const Uuid().v4();
      final ext = _pickedFile!.path.split('.').last;
      final destPath = '${progressDir.path}/$id.$ext';
      await File(_pickedFile!.path).copy(destPath);

      final weight = double.tryParse(_weightController.text.trim());
      final fat = double.tryParse(_fatController.text.trim());
      final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

      final entry = BodyProgressEntry(
        id: id,
        imagePath: destPath,
        date: DateTime.now(),
        weight: weight,
        bodyFatPercent: fat,
        note: note,
        pose: _selectedPose,
      );

      await ref.read(bodyProgressProvider.notifier).addEntry(entry);

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _ImagePickerArea extends StatelessWidget {
  final XFile? pickedFile;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  const _ImagePickerArea({
    required this.pickedFile,
    required this.onPickCamera,
    required this.onPickGallery,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (pickedFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Image.file(File(pickedFile!.path), fit: BoxFit.cover),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconButton(icon: Icons.camera_alt, onTap: onPickCamera),
                  const SizedBox(width: 6),
                  _IconButton(icon: Icons.photo_library, onTap: onPickGallery),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 48,
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.pleaseAddPhoto,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SourceButton(
                icon: Icons.camera_alt_outlined,
                label: l10n.takePhoto,
                onTap: onPickCamera,
              ),
              const SizedBox(width: 12),
              _SourceButton(
                icon: Icons.photo_library_outlined,
                label: l10n.selectFromGallery,
                onTap: onPickGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _PoseSelector extends StatelessWidget {
  final BodyPoseType selectedPose;
  final ValueChanged<BodyPoseType> onChanged;

  const _PoseSelector({
    required this.selectedPose,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: BodyPoseType.values.map((pose) {
        final isSelected = pose == selectedPose;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(pose),
            child: Container(
              margin: EdgeInsets.only(right: pose == BodyPoseType.back ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    pose.icon,
                    size: 24,
                    color: isSelected ? Colors.white : colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pose.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noPhotosYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addFirstPhoto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo),
              label: Text(l10n.addProgressPhoto),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder Image
// ---------------------------------------------------------------------------

/// Localized pose label helper
String _localizedPoseLabel(AppLocalizations l10n, BodyPoseType pose) {
  return switch (pose) {
    BodyPoseType.front => l10n.front,
    BodyPoseType.side => l10n.side,
    BodyPoseType.back => l10n.backPose,
  };
}

class _PlaceholderImage extends StatelessWidget {
  final String label;
  final Color color;

  const _PlaceholderImage({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, color: color.withValues(alpha: 0.4), size: 36),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
