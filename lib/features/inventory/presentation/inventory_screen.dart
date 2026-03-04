import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/core/time_utils.dart';
import '../../../shared/data/inventory_provider.dart';
import 'detail_view.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryProvider);
    final total = items.length;
    final fresh = items.where((i) => i.status == 'fresh').length;
    final ripening = items.where((i) => i.status == 'ripening').length;
    final critical = items
        .where((i) => i.status == 'soon_rotten' || i.status == 'rotten')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1018), // Dark UI Background
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
                backgroundColor: const Color(0xFF112616),
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
                _summaryCard(
                    'Total', total.toString(), const Color(0xFF1F2937)),
                const SizedBox(width: 8),
                _summaryCard(
                    'Fresh', fresh.toString(), const Color(0xFF064E3B)),
                const SizedBox(width: 8),
                _summaryCard(
                    'Ripening', ripening.toString(), const Color(0xFF452E07)),
                const SizedBox(width: 8),
                _summaryCard(
                    'Critical', critical.toString(), const Color(0xFF451A1A)),
              ],
            ),
          ),

          // ── Inventory List ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildItemCard(context, item);
              },
            ),
          ),
          const SizedBox(height: 80), // For nav bar
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ProduceItem item) {
    final storageLabel = item.storage == 'fridge' ? 'Fridge' : 'Room Temp';
    final storageIcon =
        item.storage == 'fridge' ? Icons.ac_unit : Icons.wb_sunny_outlined;

    return GestureDetector(
      onTap: () => showDetailViewBottomSheet(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF374151), width: 1),
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
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(storageIcon, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                          '$storageLabel · Added ${TimeUtils.timeAgo(item.addedAt)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
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
                    color: (item.status == 'fresh'
                            ? const Color(0xFF064E3B)
                            : const Color(0xFF452E07))
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item.status == 'fresh'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
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
