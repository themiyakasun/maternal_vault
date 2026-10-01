import 'dart:convert';

/// Represents a single question in the 10-item Edinburgh Postnatal Depression
/// Scale (EPDS) self-screening instrument.
class EpdsQuestion {
  const EpdsQuestion({
    required this.index,
    required this.question,
    required this.options,
  });

  final int index;
  final String question;
  /// Four options ordered by their clinical score (0, 1, 2, 3).
  final List<String> options;
}

/// Standard 10-item Edinburgh Postnatal Depression Scale (EPDS) items.
/// Each option index (0, 1, 2, 3) corresponds to its clinical point value (0–3).
const List<EpdsQuestion> kEpdsQuestions = <EpdsQuestion>[
  EpdsQuestion(
    index: 1,
    question: '1. I have been able to laugh and see the funny side of things',
    options: <String>[
      'As much as I always could (0)',
      'Not quite so much now (1)',
      'Definitely not so much now (2)',
      'Not at all (3)',
    ],
  ),
  EpdsQuestion(
    index: 2,
    question: '2. I have looked forward with enjoyment to things',
    options: <String>[
      'As much as I ever did (0)',
      'Rather less than I used to (1)',
      'Definitely less than I used to (2)',
      'Hardly at all (3)',
    ],
  ),
  EpdsQuestion(
    index: 3,
    question: '3. I have blamed myself unnecessarily when things went wrong',
    options: <String>[
      'No, never (0)',
      'Not very often (1)',
      'Yes, some of the time (2)',
      'Yes, most of the time (3)',
    ],
  ),
  EpdsQuestion(
    index: 4,
    question: '4. I have been anxious or worried for no good reason',
    options: <String>[
      'No, not at all (0)',
      'Hardly ever (1)',
      'Yes, sometimes (2)',
      'Yes, very often (3)',
    ],
  ),
  EpdsQuestion(
    index: 5,
    question: '5. I have felt scared or panicky for no very good reason',
    options: <String>[
      'No, not at all (0)',
      'No, not much (1)',
      'Yes, sometimes (2)',
      'Yes, quite a lot (3)',
    ],
  ),
  EpdsQuestion(
    index: 6,
    question: '6. Things have been getting on top of me',
    options: <String>[
      'No, I have been coping as well as ever (0)',
      'No, most of the time I have coped quite well (1)',
      'Yes, sometimes I haven\'t been coping as well as usual (2)',
      'Yes, most of the time I haven\'t been able to cope at all (3)',
    ],
  ),
  EpdsQuestion(
    index: 7,
    question: '7. I have been so unhappy that I have had difficulty sleeping',
    options: <String>[
      'No, not at all (0)',
      'Not very often (1)',
      'Yes, sometimes (2)',
      'Yes, most of the time (3)',
    ],
  ),
  EpdsQuestion(
    index: 8,
    question: '8. I have felt sad or miserable',
    options: <String>[
      'No, not at all (0)',
      'Not very often (1)',
      'Yes, quite often (2)',
      'Yes, most of the time (3)',
    ],
  ),
  EpdsQuestion(
    index: 9,
    question: '9. I have been so unhappy that I have been crying',
    options: <String>[
      'No, never (0)',
      'Only occasionally (1)',
      'Yes, quite often (2)',
      'Yes, most of the time (3)',
    ],
  ),
  EpdsQuestion(
    index: 10,
    question: '10. The thought of harming myself has occurred to me',
    options: <String>[
      'Never (0)',
      'Hardly ever (1)',
      'Sometimes (2)',
      'Yes, quite often (3)',
    ],
  ),
];

/// Standard daily mood options for maternal self-logging.
const List<String> kDailyMoodOptions = <String>[
  'Calm',
  'Happy',
  'Tired',
  'Anxious',
  'Sad',
  'Overwhelmed',
];

/// Standard daily maternal symptom options for self-logging.
const List<String> kDailySymptomOptions = <String>[
  'Difficulty Sleeping',
  'Persistent Fatigue',
  'Mild Nausea',
  'Back / Pelvic Ache',
  'Headache',
  'Hand / Ankle Swelling',
];

/// Represents a persisted 10-item EPDS self-screening and daily mood/symptom
/// log entry stored in the `moods` SQLite table.
class EpdsScreeningEntry {
  EpdsScreeningEntry({
    String? id,
    required this.itemResponses,
    int? epdsScore,
    int? anxietyScore,
    bool? sleepDisturbed,
    bool? reportedFatigue,
    this.dailyMood = 'Calm',
    this.dailySymptoms = const <String>[],
    this.notes = '',
    DateTime? createdAt,
  })  : id = id ?? 'mood_${DateTime.now().microsecondsSinceEpoch}',
        epdsScore = epdsScore ??
            itemResponses.fold<int>(0, (int sum, int item) => sum + item.clamp(0, 3)),
        anxietyScore = anxietyScore ?? _computeAnxietySubscore(itemResponses),
        sleepDisturbed = sleepDisturbed ??
            ((itemResponses.length >= 7 && itemResponses[6] >= 2) ||
                dailySymptoms.contains('Difficulty Sleeping')),
        reportedFatigue = reportedFatigue ??
            ((itemResponses.length >= 6 && itemResponses[5] >= 2) ||
                dailyMood == 'Tired' ||
                dailySymptoms.contains('Persistent Fatigue')),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final List<int> itemResponses;
  final int epdsScore;
  final int anxietyScore;
  final bool sleepDisturbed;
  final bool reportedFatigue;
  final String dailyMood;
  final List<String> dailySymptoms;
  final String notes;
  final DateTime createdAt;

  /// Computes the EPDS-3A anxiety subscale (items 3, 4, 5 -> indices 2, 3, 4).
  static int _computeAnxietySubscore(List<int> responses) {
    if (responses.length < 5) return 0;
    return (responses[2].clamp(0, 3) +
        responses[3].clamp(0, 3) +
        responses[4].clamp(0, 3));
  }

  /// Clinical risk tier label based on standard Sri Lankan FHB / WHO EPDS cutoffs.
  String get riskCategory {
    if (epdsScore >= 13 || (itemResponses.length >= 10 && itemResponses[9] >= 1)) {
      return 'High Risk (≥13)';
    }
    if (epdsScore >= 10) {
      return 'Moderate Risk (10–12)';
    }
    return 'Low Risk (0–9)';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'epds_score': epdsScore,
      'anxiety_score': anxietyScore,
      'sleep_disturbed': sleepDisturbed ? 1 : 0,
      'reported_fatigue': reportedFatigue ? 1 : 0,
      'daily_mood': dailyMood,
      'symptoms_json': jsonEncode(dailySymptoms),
      'responses_json': jsonEncode(itemResponses),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EpdsScreeningEntry.fromMap(Map<String, dynamic> map) {
    List<int> responses = List<int>.filled(10, 0);
    if (map['responses_json'] is String &&
        (map['responses_json'] as String).isNotEmpty) {
      try {
        final List<dynamic> decoded =
            jsonDecode(map['responses_json'] as String) as List<dynamic>;
        responses = decoded.map((dynamic e) => (e as num).toInt()).toList();
      } catch (_) {}
    }

    List<String> symptoms = <String>[];
    if (map['symptoms_json'] is String &&
        (map['symptoms_json'] as String).isNotEmpty) {
      try {
        final List<dynamic> decoded =
            jsonDecode(map['symptoms_json'] as String) as List<dynamic>;
        symptoms = decoded.map((dynamic e) => e.toString()).toList();
      } catch (_) {}
    }

    return EpdsScreeningEntry(
      id: map['id'] as String? ?? 'mood_unknown',
      itemResponses: responses,
      epdsScore: (map['epds_score'] as num?)?.toInt() ?? 0,
      anxietyScore: (map['anxiety_score'] as num?)?.toInt() ?? 0,
      sleepDisturbed: (map['sleep_disturbed'] as int? ?? 0) == 1,
      reportedFatigue: (map['reported_fatigue'] as int? ?? 0) == 1,
      dailyMood: map['daily_mood'] as String? ?? 'Calm',
      dailySymptoms: symptoms,
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] is String
          ? (DateTime.tryParse(map['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
