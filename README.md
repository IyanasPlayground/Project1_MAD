# Mobile App Development - Project 1<br>Campus Challenge App

## Project Overview
### Scope
The target users are students and challenge organizers. This matters to them because students would want a clear, straight forward way to make and track goals they have to be more involved on campus and utilize their resources. A challenge organizer may be college faculty, club leaders, or anyone that needs a simple way to encourage students to do things on campus with challenges, targets, and milestones.

## Core Features & Outcomes
* **Mission Cards:** Users can see many missions available to them that they can choose to add to their own assignment and complete
    * Easy way to see missions and details
* **Category Filter:** Users can filer through their board and mission by choosing a category. Each mission and target has an assigned milestone
    * Helps find a mission easier
* **Completed-Count Summary:** The dashboard shows how many missions are finished, recalculated from the current logs
    * Helps keep track of success
* **Progress Log:** Users add, view, edit, and delete progress updates for each mission, with fields and notes
    * Missions are easy to track and update
* **Mission Match Suggestion:** A mission is suggested based on match in interest/category
    * The user can view the mission or deny
    * Makes mission selection even easier

## Five Main Screens
1. **Catalog/Dashboard:** Displays mission cards, category filters, and the completed-count summary.
2. **Create/Edit:** Allows users to create or edit challenges using a title, category, description, and positive target.
3. **Detail/Activity:** Displays mission details and provides controls to start, log progress, finish, or reset a mission.
4. **History/Insights:** Displays progress history and supports creating, viewing, editing, and deleting progress logs.
5. **Settings:** Allows users to configure their default target, celebration preference, and display settings.

## System Architecture
Campus Challenge follows a layered mobile application architecture that separates the user interface, application logic, and data storage.

**Main Architecture:** Flutter Frontend -> Application Logic -> Data Layer -> SQLite / SharedPreferences / Firebase

The frontend is built with Flutter and handles the user interface, mission cards, forms, category filters, progress controls, settings, and Mission Passport. The application logic manages challenge operations, progress tracking, validation, mission lifecycle rules, completion calculations, and Mission Match suggestions.

The data layer manages communication between the application logic and storage systems. SQLite stores challenges and progress logs, while SharedPreferences stores lightweight user settings, such as the default target and celebration preference. Firebase provides cloud functionality when specific Firebase services are configured and implemented.

SQLite supports the core offline experience by keeping mission records and progress logs on the device. Completion totals are recalculated from saved records instead of being stored as separate reward values.

### Local Data Model
The application uses two related SQLite entities.

**Challenge**
- `id`: Unique challenge identifier.
- `title`: Challenge title.
- `category`: Category used for filtering and matching.
- `targetUnits`: Positive numeric target required for completion.
- `description`: Details about the challenge.

**ProgressLog**
- `id`: Unique progress-log identifier.
- `challengeId`: Identifier of the related challenge.
- `loggedAt`: Date and time of the progress entry.
- `units`: Nonnegative integer representing recorded progress.
- `note`: Optional progress description.

Each challenge can have multiple progress logs. The `challengeId` field connects each progress entry to its corresponding challenge. Editing or deleting progress logs triggers a recalculation of the relevant mission status and completed-count summary.

### Mission Match Helper
Mission Match is a rule-based smart helper that suggests challenges based on the user's preferred category and the current status of available missions.

The helper evaluates the preferred category, challenge categories, and whether each challenge has met its target. It provides a suggested mission and a brief explanation, such as "Matches art + still unfinished."

Users can select "View details" to explore the suggested mission or "Not now" to dismiss the suggestion. If the catalog is empty, the application displays "Add a challenge first." Invalid preferences should produce clear feedback rather than causing the application to crash.

The baseline method selects missions by ID order. Testing compares the rule-based helper against this baseline using normal, empty-catalog, invalid-input, tie, and counterexample cases.

### Data Integrity and Reliability
- Challenge targets must be positive.
- Progress units must be nonnegative integers.
- Every progress log must reference a valid challenge.
- Completion status must be calculated from saved progress and the current target.
- Repeated completion actions must not create duplicate completion results.
- Resetting a mission must not silently delete saved history.
- Challenge deletion must follow a defined database relationship policy.
- Failed database operations must provide clear feedback.
- Challenges, progress logs, and settings must persist after an application restart.
- Core mission tracking must work offline.

## Technology Stack
*   **Language(s)**:Dart
* **Frontend:** Flutter
* **Backend/Application Logic:** Dart application services for challenge management, progress tracking, validation, completion calculations, filtering, and Mission Match.
* **Local Database:** SQLite for persistent challenge and progress-log records.
* **Local Preferences:** SharedPreferences for lightweight settings, including the default target, celebration preference, and other display preferences.
* **Cloud Services:** Firebase for configured cloud functionality, such as authentication, synchronization, or notifications if implemented.

## Team Members
1. Janiya Green
2. Iyana Iyana Halliburton

## Primary Work Distribution
| # | Name | Focus | Backup Reviewer |
|---|------|-------|------------|
| 1 | Janiya | Data layer<br>History/Insights<br>Settings<br>progress tracking<br>Mission Match smart helper | Iyana |
| 2 | Iyana | UI<br>Mission Catalog<br>Create/Edit Mission<br>Mission Detail<br>Wireframes | Janiya |
