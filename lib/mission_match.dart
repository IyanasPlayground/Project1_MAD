import 'package:flutter/material.dart';
// Mission Match Smart AI Helper
//
// A local, rule-based helper that recommends a mission using category
// preference and progress from the current week. This is not a trained AI.
//
// The helper only recommends challenges. It does not save progress,
// complete challenges, or award stamps.
//
// Helper Rules:
// 1. Skip invalid missions.
// 2. Calculate a score for every valid mission.
// 3. Add 2 points when the category matches the saved preference.
// 4. Add 1 point when the target has not been met during the current week.
// 5. Rank by highest score, then lowest challenge ID.
// 6. If there are no valid missions, display a clear message.
//
// Note: Completed missions are still included in the ranking.
// They receive no unfinished point. This matches the scoring logic.
//
// Current period:
// Monday 12:00 a.m. through the following Monday 12:00 a.m.,
// using local calendar time.
//
// Implementation:
// 1. Inside state class, create a result using
//    MissionMatch.recommend() and your existing challenge data.
// 2. Add MissionMatchSuggestionCard to your existing screen
// 3. Recalculate the result after challenges, progress logs,
//    or the preferred category change.
// Example:
// bool _hideMissionMatch = false;
//
// Widget buildMissionMatchCard() {
//   if (_hideMissionMatch) {
//     return const SizedBox.shrink();
//   }
//
//   final result = MissionMatch.recommend(
//     challenges: challengeList,
//     progressLogs: progressLogList,
//     preferredCategory: savedPreferredCategory,
//   );
//
//   return MissionMatchSuggestionCard(
//     result: result,
//     onViewMission: (challenge) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) =>
//               ChallengeDetailScreen(challenge: challenge),
//         ),
//       );
//     },
//     onNotNow: () {
//       setState(() {
//         _hideMissionMatch = true;
//       });
//     },
//   );
// }

class MissionMatchChallenge {
  final int id;
  final String title;
  final String category;
  final int targetUnits;

  const MissionMatchChallenge({
    required this.id,
    required this.title,
    required this.category,
    required this.targetUnits,
  });
}

class MissionMatchProgressLog {
  final int id;
  final int challengeId;
  final DateTime loggedAt;
  final int units;

  const MissionMatchProgressLog({
    required this.id,
    required this.challengeId,
    required this.loggedAt,
    required this.units,
  });
}

class MissionMatchCandidate {
  final MissionMatchChallenge challenge;
  final int currentPeriodUnits;
  final bool isUnfinished;
  final int categoryPoints;
  final int unfinishedPoints;
  final int score;
  final String reason;

  const MissionMatchCandidate({
    required this.challenge,
    required this.currentPeriodUnits,
    required this.isUnfinished,
    required this.categoryPoints,
    required this.unfinishedPoints,
    required this.score,
    required this.reason,
  });
}

enum MissionMatchStatus {
  suggested,
  emptyCatalog,
  noValidMissions,
}

class MissionMatchResult {
  final MissionMatchStatus status;
  final MissionMatchCandidate? suggestion;
  final List<MissionMatchCandidate> rankedCandidates;
  final MissionMatchChallenge? baselineSuggestion;
  final String message;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int invalidChallengeCount;
  final int invalidLogCount;

  const MissionMatchResult({
    required this.status,
    required this.suggestion,
    required this.rankedCandidates,
    required this.baselineSuggestion,
    required this.message,
    required this.periodStart,
    required this.periodEnd,
    required this.invalidChallengeCount,
    required this.invalidLogCount,
  });

  bool get hasSuggestion => suggestion != null;
}

class MissionMatch {
  MissionMatch._();

  /// Returns the start of the current local calendar week
  static DateTime weekStart(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);

    return localDate.subtract(
      Duration(days: localDate.weekday - DateTime.monday),
    );
  }

  /// Calculates recommendation using local challenge and progress data
  static MissionMatchResult recommend({
    required List<MissionMatchChallenge> challenges,
    required List<MissionMatchProgressLog> progressLogs,
    required String? preferredCategory,
    DateTime? now, // makes the result repeatable in tests
  }) {
    final currentTime = (now ?? DateTime.now()).toLocal();
    final start = weekStart(currentTime);
    final end = start.add(const Duration(days: 7));

    // If there are no challenges, return a helpful message.
    if (challenges.isEmpty) {
      return MissionMatchResult(
        status: MissionMatchStatus.emptyCatalog,
        suggestion: null,
        rankedCandidates: const [],
        baselineSuggestion: null,
        message: 'Add a challenge first.',
        periodStart: start,
        periodEnd: end,
        invalidChallengeCount: 0,
        invalidLogCount: _countInvalidLogs(progressLogs),
      );
    }

    // Remove invalid challenges and sort by ascending ID
    final validChallenges = challenges.where(_isValidChallenge).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final invalidChallengeCount =
        challenges.length - validChallenges.length;

    // Challenges exist, but all challenge records are invalid
    if (validChallenges.isEmpty) {
      return MissionMatchResult(
        status: MissionMatchStatus.noValidMissions,
        suggestion: null,
        rankedCandidates: const [],
        baselineSuggestion: null,
        message: 'No valid missions are available.',
        periodStart: start,
        periodEnd: end,
        invalidChallengeCount: invalidChallengeCount,
        invalidLogCount: _countInvalidLogs(progressLogs),
      );
    }

    // Keep only progress logs with valid basic values
    final validLogs = progressLogs.where(_isValidLog).toList();
    final invalidLogCount = progressLogs.length - validLogs.length;

    // Count progress units logged during current week
    final Map<int, int> weeklyUnits = {};

    for (final log in validLogs) {
      final localLoggedAt = log.loggedAt.toLocal();

      // Include the start of the week and exclude the following Monday
      final isInsideCurrentWeek =
          !localLoggedAt.isBefore(start) && localLoggedAt.isBefore(end);

      if (isInsideCurrentWeek) {
        weeklyUnits.update(
          log.challengeId,
          (total) => total + log.units,
          ifAbsent: () => log.units,
        );
      }
    }

    // Ignore capitalization and surrounding spaces in  preference
    final preference = preferredCategory?.trim().toLowerCase() ?? '';
    final hasPreference = preference.isNotEmpty;

    // Build a scored candidate for every valid challenge
    final candidates = <MissionMatchCandidate>[];

    for (final challenge in validChallenges) {
      final units = weeklyUnits[challenge.id] ?? 0;
      final unfinished = units < challenge.targetUnits;

      final categoryMatches = hasPreference &&
          challenge.category.trim().toLowerCase() == preference;

      final categoryPoints = categoryMatches ? 2 : 0;

      final unfinishedPoints = unfinished ? 1 : 0;

      final score = categoryPoints + unfinishedPoints;

      // Explain why the challenge received its score.
      final reasons = <String>[];

      if (categoryMatches) {
        reasons.add('Matches ${challenge.category} (+2)');
      } else if (hasPreference) {
        reasons.add('Does not match $preferredCategory (+0)');
      } else {
        reasons.add('No category preference (+0)');
      }

      if (unfinished) {
        reasons.add('Still unfinished (+1)');
      } else {
        reasons.add('Target already met this week (+0)');
      }

      candidates.add(
        MissionMatchCandidate(
          challenge: challenge,
          currentPeriodUnits: units,
          isUnfinished: unfinished,
          categoryPoints: categoryPoints,
          unfinishedPoints: unfinishedPoints,
          score: score,
          reason: '${reasons.join(' + ')}.',
        ),
      );
    }

    // Rank by highest score first
    // If scores tie, the lowest challenge ID comes first
    candidates.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return a.challenge.id.compareTo(b.challenge.id);
    });

    // lowest-ID valid challenge
    final baseline = validChallenges.first;

    // Return the ranked list, top suggestion, baseline, and diagnostics
    return MissionMatchResult(
      status: MissionMatchStatus.suggested,
      suggestion: candidates.first,
      rankedCandidates: List.unmodifiable(candidates),
      baselineSuggestion: baseline,
      message: 'Your next mission: ${candidates.first.challenge.title}',
      periodStart: start,
      periodEnd: end,
      invalidChallengeCount: invalidChallengeCount,
      invalidLogCount: invalidLogCount,
    );
  }

  static bool _isValidChallenge(MissionMatchChallenge challenge) {
    return challenge.id > 0 &&
        challenge.title.trim().isNotEmpty &&
        challenge.category.trim().isNotEmpty &&
        challenge.targetUnits > 0;
  }

  static bool _isValidLog(MissionMatchProgressLog log) {
    return log.id > 0 && log.challengeId > 0 && log.units >= 0;
  }

  // Counts progress logs that fail the validation rules
  static int _countInvalidLogs(List<MissionMatchProgressLog> logs) {
    return logs.where((log) => !_isValidLog(log)).length;
  }
}

/// Displays the highest-ranked mission returned
class MissionMatchSuggestionCard extends StatelessWidget {
  final MissionMatchResult result;

  final ValueChanged<MissionMatchChallenge> onViewMission;

  final VoidCallback onNotNow;

  const MissionMatchSuggestionCard({
    super.key,
    required this.result,
    required this.onViewMission,
    required this.onNotNow,
  });

  @override
  Widget build(BuildContext context) {
    // Handle an empty catalog or a catalog with no valid missions
    if (!result.hasSuggestion) {
      return Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.message,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final candidate = result.suggestion!;
    final challenge = candidate.challenge;

    // Keep the progress indicator between 0 and 1
    final progressValue =
        (candidate.currentPeriodUnits / challenge.targetUnits)
            .clamp(0.0, 1.0)
            .toDouble();

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Identify this section as a recommendation
            Row(
              children: [
                const Icon(Icons.lightbulb_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mission Match Suggestion',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Show the suggested mission's name
            Text(
              challenge.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 4),

            // Show the category used for matching
            Text('Category: ${challenge.category}'),

            const SizedBox(height: 12),

            // Show the score calculated by the recommendation helper
            Text(
              'Match score: ${candidate.score}',
              style: Theme.of(context).textTheme.titleSmall,
            ),

            const SizedBox(height: 6),

            // Explain which rules contributed to the score
            Text(candidate.reason),

            const SizedBox(height: 12),

            // Display progress for the current week
            Text(
              'This week: ${candidate.currentPeriodUnits} '
              '/ ${challenge.targetUnits} units',
            ),

            const SizedBox(height: 6),

            // This only displays progress; it does not save anything
            LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
            ),

            const SizedBox(height: 16),

            // The user chooses whether to view or dismiss the mission
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onViewMission(challenge),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View mission'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onNotNow,
                    child: const Text('Not now'),
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