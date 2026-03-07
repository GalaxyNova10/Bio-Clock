import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/core/time_utils.dart';
import '../../../shared/data/inventory_provider.dart';
import '../../../shared/core/app_settings_provider.dart';
import '../../../shared/core/app_theme.dart';
import 'detail_view.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = items.length;
    final fresh = items.where((i) => i.status == 'fresh').length;
    final ripening = items.where((i) => i.status == 'ripening').length;
    final critical = items
        .where((i) => i.status == 'soon_rotten' || i.status == 'rotten')
        .length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Theme-aware
      appBar: AppBar(
        title: const Text('Inventory',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () =>
                  ref.read(inventoryProvider.notifier).batchPredict(),
              icon: const Icon(Icons.auto_awesome,
                  size: 16, color: Color(0xFF10B981)),
              label: const Text('Batch Predict',
                  style: TextStyle(color: Color(0xFF10B981))),
              style: TextButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF112616) : const Color(0xFFE8F5E9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary Cards ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
             child: Row(
              children: [
                _summaryCard(context,
                    'Total', total.toString(), isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)),
                const SizedBox(width: 8),
                _summaryCard(context,
                    'Fresh', fresh.toString(), isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5)),
                const SizedBox(width: 8),
                _summaryCard(context,
                    'Ripening', ripening.toString(), isDark ? const Color(0xFF452E07) : const Color(0xFFFEF3C7)),
                const SizedBox(width: 8),
                _summaryCard(context,
                    'Critical', critical.toString(), isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2)),
              ],
            ),
          ),

          // ── Inventory List ──
          Expanded(
            child: ref.read(inventoryProvider.notifier).isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF10B981)),
                        const SizedBox(height: 16),
                        Text(
                          'Fetching Live Data...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.ext.textMuted.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : items.isEmpty && !ref.watch(appSettingsProvider).demoMode
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner_outlined,
                                size: 80, color: context.ext.textMuted.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'No Items Scanned Yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: context.ext.textMuted.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan your first produce to start tracking!',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.ext.textMuted.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildItemCard(context, item, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.5 : 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ProduceItem item, bool isDark) {
    final storageLabel = item.storage == 'fridge' ? 'Fridge' : 'Room Temp';
    final storageIcon =
        item.storage == 'fridge' ? Icons.ac_unit : Icons.wb_sunny_outlined;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () => showDetailViewBottomSheet(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1F2937).withValues(alpha: 0.3)
              : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? const Color(0xFF374151)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1),
        ),
        child: Row(
          children: [
            // Produce Emoji Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: item.iconColor.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  item.emoji,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.0,
                    // Do NOT set fontFamily here — let the system pick the emoji font
                    // This ensures colour emoji rendering on both iOS and Android
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: onSurface)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(storageIcon, size: 12, color: onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                          '$storageLabel · Added ${TimeUtils.timeAgo(item.addedAt)}',
                          style: TextStyle(
                              fontSize: 12, color: onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ],
              ),
            ),
            // RUL and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(TimeUtils.formatMinutes(item.rul),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: item.status == 'fresh'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B))),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? (item.status == 'fresh'
                                ? const Color(0xFF064E3B)
                                : item.status == 'critical'
                                    ? const Color(0xFF451A1A)
                                    : const Color(0xFF452E07))
                            .withValues(alpha: 0.5)
                        : (item.status == 'fresh'
                            ? Colors.green.withValues(alpha: 0.15)
                            : item.status == 'critical'
                                ? Colors.red.withValues(alpha: 0.15)
                                : Colors.orange.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item.status == 'fresh'
                          ? (isDark ? const Color(0xFF10B981) : Colors.green)
                          : item.status == 'critical'
                              ? (isDark ? const Color(0xFFEF4444) : Colors.red)
                              : (isDark ? const Color(0xFFF59E0B) : Colors.orange),
                    ),
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
