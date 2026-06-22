class ComplaintClassifier {
  ComplaintClassifier._();
  static const Map<String, List<String>> _keywordMap = {
    'Theft': [
      'stolen',
      'theft',
      'steal',
      'took',
      'missing',
      'pickpocket',
      'burglar',
      'burglary',
      'shoplifting',
      'snatch',
      'snatched',
      'took my',
      'wallet',
      'phone stolen',
      'bag stolen',
      'car stolen',
      'robbery',
    ],
    'Robbery': [
      'robbery',
      'robbed',
      'mugging',
      'mugged',
      'armed',
      'gun',
      'knife',
      'threatened',
      'weapon',
      'hijack',
      'held up',
      'demand money',
    ],
    'Assault': [
      'assault',
      'attack',
      'beat',
      'beaten',
      'hit',
      'punch',
      'punched',
      'kick',
      'kicked',
      'fought',
      'fight',
      'physical',
      'violence',
      'hurt',
      'injured',
      'wound',
      'blood',
      'broken',
      'bone',
    ],
    'Fraud': [
      'fraud',
      'scam',
      'cheated',
      'cheat',
      'fake',
      'forgery',
      'forged',
      'deceive',
      'deceived',
      'false',
      'impersonate',
      'identity',
      'money lost',
      'paid but',
      'not delivered',
      'online shop',
      'bkash',
      'nagad',
      'transfer',
    ],
    'Cybercrime': [
      'hack',
      'hacked',
      'hacking',
      'cyber',
      'online',
      'social media',
      'facebook',
      'account',
      'password',
      'phishing',
      'email',
      'virus',
      'malware',
      'data breach',
      'blackmail',
      'screenshot',
      'leaked',
      'instagram',
      'whatsapp',
      'telegram',
    ],
    'Drug Offense': [
      'drug',
      'drugs',
      'narcotics',
      'heroin',
      'yaba',
      'cocaine',
      'marijuana',
      'weed',
      'dealer',
      'selling drugs',
      'substance',
      'addiction',
    ],
    'Murder': [
      'murder',
      'killed',
      'death',
      'dead',
      'homicide',
      'shooting',
      'stabbed',
      'shot',
      'killed someone',
      'body found',
      'dead body',
      'corpse',
    ],
    'Kidnapping': [
      'kidnap',
      'kidnapped',
      'abduct',
      'abducted',
      'missing person',
      'taken away',
      'held captive',
      'ransom',
      'forced',
    ],
    'Sexual Harassment': [
      'harassment',
      'harass',
      'sexual',
      'molest',
      'rape',
      'raped',
      'inappropriate touch',
      'eve teasing',
      'stalking',
      'stalked',
      'unwanted',
      'grope',
      'indecent',
    ],
    'Domestic Violence': [
      'domestic',
      'husband',
      'wife',
      'spouse',
      'family violence',
      'home violence',
      'beat wife',
      'beat husband',
      'abuse',
      'abused',
      'dowry',
      'torture',
      'tortured at home',
    ],
    'Vandalism': [
      'vandalism',
      'vandalize',
      'damaged',
      'broken',
      'graffiti',
      'destroyed',
      'property damage',
      'smashed',
      'spray paint',
      'broken window',
    ],
    'Corruption': [
      'bribe',
      'bribery',
      'corruption',
      'corrupt',
      'extortion',
      'illegal fee',
      'demanded money',
      'government official',
      'public servant',
    ],
    'Traffic Violation': [
      'traffic',
      'accident',
      'reckless driving',
      'hit and run',
      'speeding',
      'drunk driving',
      'signal',
      'license',
      'vehicle',
      'car crash',
      'motorbike',
      'road accident',
    ],
  };
  static ClassificationResult? classify(String description) {
    if (description.trim().length < 10) return null;
    final lower = description.toLowerCase();
    final scores = <String, int>{};
    for (final entry in _keywordMap.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          score++;
        }
      }
      if (score > 0) scores[entry.key] = score;
    }
    if (scores.isEmpty) return null;
    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final totalKeywords = _keywordMap[best.key]!.length;
    final confidence = (best.value / totalKeywords).clamp(0.0, 1.0);
    final level = confidence >= 0.3
        ? ConfidenceLevel.high
        : confidence >= 0.1
            ? ConfidenceLevel.medium
            : ConfidenceLevel.low;
    return ClassificationResult(
      category: best.key,
      confidence: level,
      score: best.value,
    );
  }
}

enum ConfidenceLevel { high, medium, low }

class ClassificationResult {
  final String category;
  final ConfidenceLevel confidence;
  final int score;
  const ClassificationResult({
    required this.category,
    required this.confidence,
    required this.score,
  });
  String get confidenceLabel {
    switch (confidence) {
      case ConfidenceLevel.high:
        return 'High confidence';
      case ConfidenceLevel.medium:
        return 'Medium confidence';
      case ConfidenceLevel.low:
        return 'Low confidence';
    }
  }
}
