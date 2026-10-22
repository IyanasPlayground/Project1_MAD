# AI / Smart Helper
Mission Match is a local, rule-based recommendation helper in Campus Challenge. It recommends a challenge using the user's saved preferred category and the challenge's progress during the current week. It is a rule-based smart helper that automatically recommends the first unfinished, valid mission in stable ID order.
The helper only recommends challenges. It does not save progress, complete challenges, or award stamps.

## Method Label
Mission Match uses two simple rules to calculate a score for each valid challenge:

- Add 2 points if the challenge category matches the user's saved preferred category.
- Add 1 point if the challenge target has not been met during the current week.
- Add the points together to calculate the final score.
- Rank challenges from highest score to lowest score.
- If two challenges have the same score, recommend the challenge with the lower ID first.

## Benefit
Mission Match helps users decide what challenge to work on without having to browse the entire challenge list. It considers the user's category preference and current progress to provide a quick suggestion while making the mission board easier to use.

## Inputs/Units
- `Challenge.id`: provides stable ordering when scores tie.
- `Challenge.title`: identifies the recommended challenge.
- `Challenge.category`: determines whether the challenge matches the preference.
- `Challenge.targetUnits`: defines how many units are needed to complete the challenge.
- `ProgressLog.challengeId`: connects progress to its challenge.
- `ProgressLog.units`: records progress units.
- `ProgressLog.loggedAt`: determines whether progress falls in the current period.
- `preferredChallengeCategory`: a category preference saved in SharedPreferences.

## Rationale/Alternative
The +2 category-match weight gives the user's saved preference more influence than unfinished status, which is worth +1. This allows the helper to recommend a challenge that matches the user's interests while still considering progress.

The method is easy to understand, implement, and test. It also provides a clear explanation for each score contribution.

An alternative would be to recommend only unfinished challenges and use category preference as a tie-breaker.

## Comparison Baseline
Stable ID order with no scoring
The baseline ignores category preference and progress. It selects the valid challenge with the lowest ID. This makes it possible to compare the rule-based recommendation with a simple, predictable ordering.

## Case Tables
**Baseline**
| cases | case ID | inputs | expected behavior | actual behavior | pass/fail |
|-------|---------|--------|-------------------|----------------|-----------|
| normal | n | valid challenge | Select challenge ID regardless of category or progress | n | n |
| empty/insufficient input | n | empty challenge list | no baseline challenge | n | n |
| invalid input | n | Challenge ID -1 is invalid | Ignore invalid challenge and selected last valid one | n | n |
| boundary/tie/outlier | n | n | n | n | n |
| counterexample | n | First ID is unfinished & doesnt match the preference; ID 2 matches preference and is unfinished | baseline ignores scores | n | n |

**Helper**
| cases | case ID | inputs | expected behavior | actual behavior | pass/fail |
|-------|---------|--------|-------------------|----------------|-----------|
| normal | n | valid challenge | Select challenge ID regardless of category or progress | n | n |
| empty/insufficient input | n | empty challenge list | no baseline challenge | n | n |
| invalid input | n | Challenge ID -1 is invalid | Ignore invalid challenge and selected last valid one | n | n |
| boundary/tie/outlier | n | n | n | n | n |
| counterexample | n | First ID is unfinished & doesnt match the preference; ID 2 matches preference and is unfinished | baseline ignores scores | n | n |

## Metrics/Sample Size
The initial test plan contains five baseline cases and five helper cases, for a total of 10 planned cases.

The cases cover normal inputs, an empty catalog, invalid records, week-boundary behavior, score ties, and a counterexample where the scored helper produces a different result from the baseline.

The main comparison metric is whether the selected challenge matches the expected result. Additional checks include:
- Whether invalid challenges and invalid logs are counted
- Whether progress is counted only within the current local calendar week
- Whether the category and unfinished points are calculated correctly
- Whether tied scores are ordered by ascending challenge ID
- Whether an empty catalog returns the correct message
- Whether the recommendation leaves progress and stamps unchanged

## Counterexample
A counterexample occurs when the baseline and Mission Match recommend different challenges.

## Revision/Limitation
The implementation uses a simple scoring formula instead of a trained recommendation model. Its behavior is predictable, explainable, and easy to test, but it does not learn from the user's past choices.

One limitation is that completed challenges remain eligible for recommendation. Because category matching is worth 2 points and unfinished status is worth 1 point, a completed challenge in the preferred category can outrank an unfinished challenge in a different category. If the intended behavior is to recommend only unfinished challenges, the ranking logic should be revised to filter out completed challenges before selecting the suggestion.

Another limitation is that progress is calculated for the current week only. Progress from previous weeks does not contribute to the current score. The helper also depends on the app passing the latest challenge data, progress logs, and saved category preference. The result must be recalculated after those values change. (Something that can be changed easily if desired)

## User-Control/Offline Evidence
Mission Match is user-controlled because the user decides whether to select "View mission" or "Not now." Viewing a suggestion is handled by the existing app's navigation, while dismissing it hides the suggestion without changing progress or stamps.
The recommendation logic runs locally and uses the challenge list, progress logs, and saved category preference supplied by the app. It does not require a remote AI service or internet access to calculate the recommendation.
The category preference is intended to be stored in SharedPreferences. The recommendation helper receives that saved value as an input; the app is responsible for loading the preference and passing it to the helper.

[evidence picture of device offline while selecting options]