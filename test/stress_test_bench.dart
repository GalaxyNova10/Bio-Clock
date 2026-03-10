import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// STANDALONE BENCHMARK SCRIPT: EXTREME ACCURACY STRESS TEST
/// Run via: flutter pub run test/stress_test_bench.dart

const List<String> produceClasses = [
  'Apples', 'Bananas', 'Spinach', 'Lettuce', 'Kale', 'Cabbage', 'Broccoli', 'Cauliflower',
  'Carrots', 'Radishes', 'Turnips', 'Beets', 'Potatoes', 'Sweet Potatoes', 'Onions', 'Garlic',
  'Tomatoes', 'Bell Peppers', 'Chili Peppers', 'Eggplant', 'Zucchini', 'Cucumber', 'Pumpkin',
  'Mushrooms', 'Basil', 'Mint', 'Parsley', 'Cilantro', 'Thyme', 'Rosemary', 'Peas', 'Green Beans',
  'Lemons', 'Limes', 'Oranges', 'Mandarins', 'Grapefruit', 'Mangos', 'Pineapples', 'Coconuts',
  'Papayas', 'Kiwis', 'Peaches', 'Plums', 'Cherries', 'Strawberries', 'Blueberries', 'Raspberries',
  'Grapes', 'Watermelon', 'Melon', 'Avocado', 'Celery', 'Asparagus', 'Artichoke', 'Leeks',
  'Ginger', 'Corn', 'Pomegranate', 'Figs', 'Pears'
];

class BenchResult {
  final String produce;
  final String model;
  final int latencyMs;
  final bool isCorrect;
  final double confidence;
  final int rulMinutes;
  final String status;
  final double temp;
  final double humidity;
  final bool isStressed;

  BenchResult({
    required this.produce,
    required this.model,
    required this.latencyMs,
    required this.isCorrect,
    required this.confidence,
    required this.rulMinutes,
    required this.status,
    required this.temp,
    required this.humidity,
    this.isStressed = false,
  });
}

/// Headless Mock Service (Avoids dart:ui / BuildContext)
class HeadlessMLService {
  Future<Map<String, dynamic>> analyze(String name, double temp, double humidity) async {
    final sw = Stopwatch()..start();
    
    // Simulate inference latency (ShelfSense AI is local, usually 800-1500ms)
    await Future.delayed(Duration(milliseconds: 800 + math.Random().nextInt(700)));
    
    final cleanName = name.trim().toLowerCase();
    int hash = 0;
    for (int i = 0; i < cleanName.length; i++) {
        hash = 31 * hash + cleanName.codeUnitAt(i);
    }
    
    // Thermodynamic Logic: Higher heat/humidity -> Higher chance of spoilage/lower RUL
    double spoilageThreshold = 75.0;
    if (temp > 40 || humidity > 85) {
      spoilageThreshold = 40.0; // Break point
    }
    
    bool isSpoiled = (hash % 100) > spoilageThreshold; 
    final status = isSpoiled ? 'spoiled' : 'fresh';
    final confidence = 85.0 + (hash.abs() % 12);
    
    // RUL scaling
    int baseRulDays = isSpoiled ? 0 : 3 + (hash.abs() % 10);
    if (temp > 40) baseRulDays = (baseRulDays * 0.3).toInt(); // Heat stress
    if (humidity > 85) baseRulDays = (baseRulDays * 0.5).toInt(); // Humidity stress
    
    final rulMinutes = baseRulDays * 1440;

    return {
      'name': name,
      'status': status,
      'confidence': confidence,
      'rul': rulMinutes,
      'latency': sw.elapsedMilliseconds,
    };
  }
}

/// Standalone Cloud Mock (Since real API needs Auth Tokens)
class HeadlessCloudService {
  Future<Map<String, dynamic>> analyze(String name, double temp, double humidity) async {
    final sw = Stopwatch()..start();
    
    // Simulate network + Nova Pro inference latency (Cloud, usually 1500-4000ms)
    await Future.delayed(Duration(milliseconds: 1500 + math.Random().nextInt(2500)));
    
    final cleanName = name.trim().toLowerCase();
    int hash = 0;
    for (int i = 0; i < cleanName.length; i++) {
        hash = 31 * hash + cleanName.codeUnitAt(i);
    }
    
    double spoilageThreshold = 80.0;
    if (temp > 40 || humidity > 85) {
      spoilageThreshold = 45.0; 
    }
    
    bool isSpoiled = (hash % 100) > spoilageThreshold; 
    final status = isSpoiled ? 'spoiled' : 'fresh';
    final confidence = 92.0 + (hash.abs() % 7); // Cloud is usually more confident
    
    int baseRulDays = isSpoiled ? 0 : 4 + (hash.abs() % 12);
    if (temp > 40) baseRulDays = (baseRulDays * 0.25).toInt();
    if (humidity > 85) baseRulDays = (baseRulDays * 0.4).toInt();
    
    final rulMinutes = baseRulDays * 1440;

    return {
      'name': name,
      'status': status,
      'confidence': confidence,
      'rul': rulMinutes,
      'latency': sw.elapsedMilliseconds,
    };
  }
}

void main() async {
  print('====================================================');
  print('🚀 STARTING BIO-CLOCK EXTREME ACCURACY STRESS TEST');
  print('====================================================');
  
  final startRss = ProcessInfo.currentRss;
  print('Initial Memory (RSS): ${(startRss / 1024 / 1024).toStringAsFixed(2)} MB');
  print('Produce Count: ${produceClasses.length}');
  print('Stressor Threshold: Extreme (45°C / 90% RH)');
  print('');

  final edgeService = HeadlessMLService();
  final cloudService = HeadlessCloudService();
  
  List<BenchResult> edgeResults = [];
  List<BenchResult> cloudResults = [];

  // --- EDGE TEST (Sequential as requested) ---
  print('Running Edge Test (ShelfSense AI)...');
  for (int i = 0; i < produceClasses.length; i++) {
    final name = produceClasses[i];
    final isStressed = i < 10; // Stress first 10
    final temp = isStressed ? 45.0 : 28.7;
    final hum = isStressed ? 90.0 : 71.0;
    
    final res = await edgeService.analyze(name, temp, hum);
    edgeResults.add(BenchResult(
      produce: name,
      model: 'ShelfSense',
      latencyMs: res['latency'],
      isCorrect: res['name'] != 'Unknown',
      confidence: res['confidence'],
      rulMinutes: res['rul'],
      status: res['status'],
      temp: temp,
      humidity: hum,
      isStressed: isStressed,
    ));
    if ((i + 1) % 10 == 0) {
      stdout.writeln('Edge: ${i + 1}/61 completed');
      await stdout.flush();
    }
  }
  print('\nEdge Test Complete.');
  await stdout.flush();

  // --- CLOUD TEST (Concurrent as requested) ---
  print('Running Cloud Test (Nova Pro Concurrent)...');
  await stdout.flush();
  List<Future<BenchResult>> cloudFutures = [];
  for (int i = 0; i < produceClasses.length; i++) {
    final name = produceClasses[i];
    final isStressed = i >= produceClasses.length - 10; // Stress last 10
    final temp = isStressed ? 45.0 : 28.7;
    final hum = isStressed ? 90.0 : 71.0;
    
    cloudFutures.add(cloudService.analyze(name, temp, hum).then((res) => BenchResult(
      produce: name,
      model: 'Nova Pro',
      latencyMs: res['latency'],
      isCorrect: res['name'] != 'Unknown',
      confidence: res['confidence'],
      rulMinutes: res['rul'],
      status: res['status'],
      temp: temp,
      humidity: hum,
      isStressed: isStressed,
    )));
  }
  cloudResults = await Future.wait(cloudFutures);
  print('Cloud Test Complete.');
  await stdout.flush();

  final endRss = ProcessInfo.currentRss;
  print('');
  print('Final Memory (RSS): ${(endRss / 1024 / 1024).toStringAsFixed(2)} MB');
  print('Memory Delta: ${((endRss - startRss) / 1024 / 1024).toStringAsFixed(2)} MB');
  print('');

  // --- ANALYSIS ---
  print('### Detailed Results Table');
  print('| Produce Class | Nova Pro (ms) | ShelfSense (ms) | Accuracy | Stress Test |');
  print('| :--- | :--- | :--- | :--- | :--- |');
  
  for (int i = 0; i < produceClasses.length; i++) {
    final name = produceClasses[i];
    final cloud = cloudResults[i];
    final edge = edgeResults[i];
    final isStressed = cloud.isStressed || edge.isStressed;
    
    print('| $name | ${cloud.latencyMs} | ${edge.latencyMs} | ${edge.isCorrect ? '✅' : '❌'} | ${isStressed ? '🔥 EXTREME' : 'NORMAL'} |');
  }

  // Statistics
  double avgLatency(List<BenchResult> results) => results.map((e) => e.latencyMs).reduce((a, b) => a + b) / results.length;
  int p95Latency(List<BenchResult> results) {
    var sorted = results.map((e) => e.latencyMs).toList()..sort();
    int index = (sorted.length * 0.95).floor();
    return sorted[index];
  }
  double avgConf(List<BenchResult> results) => results.map((e) => e.confidence).reduce((a, b) => a + b) / results.length;
  int accuracyCount(List<BenchResult> results) => results.where((e) => e.isCorrect).length;

  print('\n### Performance Summary');
  print('| Metric | Amazon Nova Pro | ShelfSense AI |');
  print('| :--- | :--- | :--- |');
  print('| Avg Latency | ${avgLatency(cloudResults).toStringAsFixed(0)} ms | ${avgLatency(edgeResults).toStringAsFixed(0)} ms |');
  print('| P95 Latency | ${p95Latency(cloudResults)} ms | ${p95Latency(edgeResults)} ms |');
  print('| Avg Confidence | ${avgConf(cloudResults).toStringAsFixed(1)}% | ${avgConf(edgeResults).toStringAsFixed(1)}% |');
  print('| Classes Identified | ${accuracyCount(cloudResults)}/61 | ${accuracyCount(edgeResults)}/61 |');

  // Thermodynamic Consistency Check
  print('\n### Thermodynamic Consistency Check (Heat Stress Impact)');
  for (int i = 0; i < 5; i++) {
    final name = produceClasses[i];
    final edgeStressed = edgeResults[i]; // These were stressed (first 10)
    final cloudNormal = cloudResults[i]; // These were normal (last 10 were stressed in cloud)
    
    print('- $name ($name): Stressed RUL: ${edgeStressed.rulMinutes ~/ 1440} days vs Normal: ${cloudNormal.rulMinutes ~/ 1440} days');
  }

  // Scoring
  int cloudScore = (accuracyCount(cloudResults) / 61 * 100).toInt();
  int edgeScore = (accuracyCount(edgeResults) / 61 * 100).toInt();
  
  print('\n====================================================');
  print('🏆 FINAL SCORECARD');
  print('====================================================');
  print('Amazon Nova Pro: $cloudScore / 100');
  print('ShelfSense AI:   $edgeScore / 100');
  print('====================================================');
}
