import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../core/app_settings_provider.dart';
import '../core/aws_config.dart';
import '../ui/produce_emoji.dart';
import 'api_client.dart';
import 'auth_provider.dart';

/// Produce item model used across the app, now featuring S3 integration.
class ProduceItem {
  final String id;
  final String name;
  final int rul; // remaining useful life in minutes
  final String status; // fresh, ripening, soon_rotten, rotten
  final IconData icon; // Fallback icon
  final Color iconColor;
  final String emoji;
  final String storage; // freezer, fridge, room
  final DateTime addedAt;
  final String? s3Url; // AWS S3 Thumbnail URL

  const ProduceItem({
    required this.id,
    required this.name,
    required this.rul,
    required this.status,
    required this.icon,
    required this.iconColor,
    required this.emoji,
    this.storage = 'fridge',
    required this.addedAt,
    this.s3Url,
  });

  ProduceItem copyWith({
    String? name,
    int? rul,
    String? status,
    IconData? icon,
    Color? iconColor,
    String? emoji,
    String? storage,
    String? s3Url,
  }) {
    return ProduceItem(
      id: id,
      name: name ?? this.name,
      rul: rul ?? this.rul,
      status: status ?? this.status,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      emoji: emoji ?? this.emoji,
      storage: storage ?? this.storage,
      addedAt: addedAt,
      s3Url: s3Url ?? this.s3Url,
    );
  }
}

/// Demo produce data — connected to mock S3 eu-north-1 bucket.
final List<ProduceItem> demoProduce = [
  ProduceItem(
    id: 'd1',
    name: 'Fresh Spinach',
    rul: 48 * 60,
    status: 'fresh',
    icon: Icons.grass,
    iconColor: const Color(0xFF10B981),
    emoji: ProduceEmoji.getEmoji('Fresh Spinach'),
    storage: 'fridge',
    addedAt: DateTime.now().subtract(const Duration(hours: 4)),
  ),
  ProduceItem(
    id: 'd2',
    name: 'Tomatoes',
    rul: 18 * 60,
    status: 'ripening',
    icon: Icons.circle,
    iconColor: const Color(0xFFEF4444),
    emoji: ProduceEmoji.getEmoji('Tomatoes'),
    storage: 'room',
    addedAt: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  ProduceItem(
    id: 'd3',
    name: 'Bananas',
    rul: 32 * 60,
    status: 'ripening',
    icon: Icons.spa,
    iconColor: const Color(0xFFF59E0B),
    emoji: ProduceEmoji.getEmoji('Bananas'),
    storage: 'room',
    addedAt: DateTime.now().subtract(const Duration(hours: 6)),
  ),
  ProduceItem(
    id: 'd4',
    name: 'Avocado',
    rul: 40 * 60,
    status: 'fresh',
    icon: Icons.eco,
    iconColor: const Color(0xFF10B981),
    emoji: ProduceEmoji.getEmoji('Avocado'),
    storage: 'fridge',
    addedAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  ProduceItem(
    id: 'd5',
    name: 'Carrots',
    rul: 80 * 60,
    status: 'fresh',
    icon: Icons.restaurant,
    iconColor: const Color(0xFFF97316),
    emoji: ProduceEmoji.getEmoji('Carrots'),
    storage: 'fridge',
    addedAt: DateTime.now().subtract(const Duration(hours: 12)),
  ),
  ProduceItem(
    id: 'd6',
    name: 'Bell Pepper',
    rul: 60 * 60,
    status: 'fresh',
    icon: Icons.local_florist,
    iconColor: const Color(0xFFEF4444),
    emoji: ProduceEmoji.getEmoji('Bell Pepper'),
    storage: 'fridge',
    addedAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  ProduceItem(
    id: 'd7',
    name: 'Cucumber',
    rul: 36 * 60,
    status: 'fresh',
    icon: Icons.grass,
    iconColor: const Color(0xFF10B981),
    emoji: ProduceEmoji.getEmoji('Cucumber'),
    storage: 'fridge',
    addedAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
];

class InventoryNotifier extends StateNotifier<List<ProduceItem>> {
  final Ref _ref;
  bool isLoading = false;

  InventoryNotifier(this._ref) : super([]) {
    // Listen for demo mode changes
    _ref.listen<AppSettings>(appSettingsProvider, (prev, next) {
      if (prev?.demoMode != next.demoMode) {
        if (next.demoMode) {
          isLoading = false;
          state = [...demoProduce];
        } else {
          isLoading = true;
          state = []; // Clear mocks and aggressively notify loading state
          fetchFromCloud(); // Real cloud fetch
        }
      }
    });

    // Initialize with demo data if demo mode is on
    final settings = _ref.read(appSettingsProvider);
    if (settings.demoMode) {
      state = [...demoProduce];
    }
  }

  void addItem(ProduceItem item) {
    state = [item, ...state];
    _syncToCloud(item);
  }

  /// Helper to decode Cognito JWT specifically extracting the 'sub'
  String? _getUserIdFromToken() {
    final token = _ref.read(authProvider).idToken;
    if (token == null) {
      final email = _ref.read(authProvider).email;
      return email != null ? 'USER#$email' : 'USER#UNKNOWN';
    }
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'USER#UNKNOWN';
      final payloadStr = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = jsonDecode(payloadStr);
      final sub = payloadMap['sub']?.toString();
      return sub != null ? 'USER#$sub' : 'USER#UNKNOWN';
    } catch (_) {
      return 'USER#UNKNOWN';
    }
  }

  /// Sync a newly scanned item to DynamoDB.
  Future<void> _syncToCloud(ProduceItem item) async {
    if (!AwsConfig.useCloudBackend) return;
    try {
      final api = _ref.read(apiClientProvider);
      final userId = _getUserIdFromToken();
      await api.addItem({
        'userId': userId,
        'id': item.id,
        'name': item.name,
        'rul': item.rul,
        'status': item.status,
        'storage': item.storage,
        'emoji': item.emoji,
      });
    } catch (_) {
      // Offline — item stays in local state, sync later
    }
  }

  /// Fetch inventory from DynamoDB specifically filtered by the authenticated userId.
  Future<void> fetchFromCloud() async {
    if (!AwsConfig.useCloudBackend) return;
    try {
      isLoading = true;
      // notifyListeners() equivalent in Riverpod - we just trigger a state reassignment
      state = state.isEmpty ? [] : [...state];
      
      final api = _ref.read(apiClientProvider);
      final userId = _getUserIdFromToken();
      final cloudItems = await api.fetchInventory(userId);
      
      final parsed = cloudItems.map((json) => ProduceItem(
            id: json['SK']?.toString().replaceFirst('ITEM#', '') ?? json['id'] as String,
            name: json['name'] as String,
            rul: (json['rul'] as num).toInt(),
            status: json['status'] as String,
            icon: Icons.eco,
            iconColor: const Color(0xFF10B981),
            emoji: ProduceEmoji.getEmoji(json['name'] as String),
            storage: json['storage'] as String? ?? 'fridge',
            addedAt: DateTime.tryParse(json['created_at'] ?? json['addedAt'] ?? '') ??
                DateTime.now(),
            s3Url: json['s3_key'] != null ? 'https://${AwsConfig.s3BucketName}.s3.amazonaws.com/${json['s3_key']}' : json['s3Url'] as String?,
          )).toList();
          
      // Merge: keeping only live cloud items to strictly wipe out mock items
      state = parsed;
    } catch (_) {
      // Offline — keep local state
    } finally {
      isLoading = false;
      state = [...state];
    }
  }

  /// Mark an item as donated and update the cloud safely.
  Future<void> donateItem(String itemId) async {
    final originalState = state;
    // Optimistic UI update
    removeItem(itemId);
    
    if (AwsConfig.useCloudBackend) {
      try {
        final api = _ref.read(apiClientProvider);
        final userId = _getUserIdFromToken();
        await api.donateItem(userId ?? 'USER#UNKNOWN', 'ITEM#$itemId');
      } catch (e) {
        // Rollback on failure
        state = originalState;
        debugPrint('Donation failed: $e');
      }
    }
  }

  void removeItem(String id) {
    state = state.where((i) => i.id != id).toList();
  }

  void updateStorage(String id, String newStorage) {
    state = state.map((item) {
      if (item.id != id) return item;

      // The 5.41x Stress Factor logic based on temp (Q10 logic approx)
      final factors = {'room': 1.0, 'fridge': 2.4, 'freezer': 5.41};
      final oldFactor = factors[item.storage] ?? 1.0;
      final newFactor = factors[newStorage] ?? 1.0;

      final newRul = (item.rul / oldFactor * newFactor).round();
      final newStatus = _statusFromRul(newRul);

      return item.copyWith(
        storage: newStorage,
        rul: newRul,
        status: newStatus,
      );
    }).toList();
  }

  Future<void> batchPredict() async {
    if (AwsConfig.useCloudBackend) {
      try {
        final api = _ref.read(apiClientProvider);
        final cloudItems = await api.batchPredict();
        final parsed = cloudItems.map((json) => ProduceItem(
              id: json['id'] as String,
              name: json['name'] as String,
              rul: json['rul'] as int,
              status: json['status'] as String,
              icon: Icons.eco,
              iconColor: const Color(0xFF10B981),
              emoji: ProduceEmoji.getEmoji(json['name'] as String),
              storage: json['storage'] as String? ?? 'fridge',
              addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
                  DateTime.now(),
            )).toList();
        state = parsed;
        return;
      } catch (_) {
        // Fallback to local Q10 simulation
      }
    }
    // Local fallback — simulate Q10 decay
    state = state.map((item) {
      final decayMultiplier = item.storage == 'room' ? 0.85 : 0.98;
      final newRul = (item.rul * decayMultiplier).round();
      final newStatus = _statusFromRul(newRul);
      return item.copyWith(rul: newRul, status: newStatus);
    }).toList();
  }

  void clearAll() {
    state = [];
  }

  String _statusFromRul(int rulMinutes) {
    if (rulMinutes > 36 * 60) return 'fresh';
    if (rulMinutes > 18 * 60) return 'ripening';
    if (rulMinutes > 6 * 60) return 'soon_rotten';
    return 'rotten';
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<ProduceItem>>((ref) {
  return InventoryNotifier(ref);
});
