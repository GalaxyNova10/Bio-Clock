class LocalMLService {
  /// Web mock initialization
  Future<void> initialize() async {
    // No-op for web
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Run mock inference for Web using dynamic hashing of the provided [fallbackName]
  Future<Map<String, dynamic>> analyzeImage(dynamic imageFile, String fallbackName) async {
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    // Dynamic mock logic based on the user's input string
    final cleanName = fallbackName.trim().toLowerCase();
    
    // Hash the string to generate consistent but varied results
    int hash = 0;
    for (int i = 0; i < cleanName.length; i++) {
        hash = 31 * hash + cleanName.codeUnitAt(i);
    }
    
    // Use hash to determine status
    bool isSpoiled = (hash % 100) > 75; // ~25% chance of being spoiled based on string
    final status = isSpoiled ? 'spoiled' : 'fresh';
    
    // Derive confidence between 82 and 98
    final confidence = 82 + (hash.abs() % 17);
    
    // Derive RUL: 0 if spoiled, otherwise 2 to 14 days (in minutes: 1440 * days)
    final rulDays = isSpoiled ? 0 : 2 + (hash.abs() % 13);
    final rulMinutes = rulDays * 1440;

    return {
      'name': fallbackName,
      'status': status,
      'confidence': confidence,
      'rul': rulMinutes,
    };
  }
}
