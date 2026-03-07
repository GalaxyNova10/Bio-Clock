import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/core/time_utils.dart';
import '../../../shared/data/inventory_provider.dart';

void showDetailViewBottomSheet(BuildContext context, ProduceItem item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _DetailViewSheet(initialItem: item),
  );
}

class _DetailViewSheet extends ConsumerWidget {
  final ProduceItem initialItem;

  const _DetailViewSheet({required this.initialItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryProvider);
    final item = items.firstWhere((i) => i.id == initialItem.id,
        orElse: () => initialItem);

    final isFresh = item.status == 'fresh';
    final remainingTime = TimeUtils.formatMinutes(item.rul)
        .split(' ')[0]; // Just the number/unit part like "1d" or "18h"

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1018),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Item Details',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Produce Emoji — large, above the title
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color:
                  (isFresh ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isFresh
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B))
                    .withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                item.emoji,
                style: const TextStyle(
                  fontSize: 40,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(item.name,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text('ID: ${item.id}',
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 32),

          // ── 2x2 Info Grid ──
          Row(
            children: [
              _infoCard('Remaining', remainingTime, Icons.access_time,
                  isFresh ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
              const SizedBox(width: 16),
              _infoCard('Added', TimeUtils.timeAgo(item.addedAt),
                  Icons.calendar_today, Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _cardWrapper(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.kitchen, size: 14, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Storage',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Theme(
                        data: Theme.of(context)
                            .copyWith(canvasColor: const Color(0xFF1F2937)),
                        child: DropdownButton<String>(
                          value: item.storage,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: const Color(0xFF1F2937),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.white),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          items:
                              ['room', 'fridge', 'freezer'].map((String value) {
                            final label = value == 'room'
                                ? 'Room Temp'
                                : (value == 'fridge' ? 'Fridge' : 'Freezer');
                            final icon = value == 'room'
                                ? '🧺'
                                : (value == 'fridge' ? '❄️' : '🧊');
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text('$icon $label'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(inventoryProvider.notifier)
                                  .updateStorage(item.id, val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _infoCard('Environment', isFresh ? 'Optimal' : 'Standard Mode',
                  Icons.thermostat, Colors.white),
            ],
          ),

          const SizedBox(height: 24),
          const Text('SPOILAGE TIMELINE',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey)),
          const SizedBox(height: 24),

          // ── Timeline ──
          _timelineItem('Item Scanned & Registered',
              TimeUtils.timeAgo(item.addedAt), const Color(0xFF3B82F6)),
          _timelineItem(
              'Freshness Modeling Active',
              'Q10 rate calculated based on ${item.storage == 'fridge' ? 'Fridge' : 'Room Temp'}',
              const Color(0xFF10B981)),
          _timelineItem('Critical Expiration Notice',
              'Estimated at $remainingTime remaining', Colors.grey),
        ],
      ),
      ),
    );
  }

  Widget _cardWrapper(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF374151), width: 1),
      ),
      child: child,
    );
  }

  Widget _infoCard(
      String label, String value, IconData icon, Color valueColor) {
    return Expanded(
      child: _cardWrapper(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _timelineItem(String title, String subtitle, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
