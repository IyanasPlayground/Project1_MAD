import 'package:flutter/material.dart';
import 'data/database_helper.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final ChallengeRecord challenge;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengeDetailScreen> createState() =>
      _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final DatabaseHelper _database = DatabaseHelper();
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<ActivityRecord> _activities = [];
  List<NoteRecord> _notes = [];
  int _weeklyUnits = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final id = widget.challenge.id!;

    final activities = await _database.getActivities(id);
    final notes = await _database.getNotes(id);
    final logs = await _database.getProgressLogs(id);

    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final weeklyUnits = logs
        .where(
          (log) =>
              !log.loggedAt.isBefore(weekStart) &&
              log.loggedAt.isBefore(weekEnd),
        )
        .fold<int>(0, (total, log) => total + log.units);

    if (!mounted) return;

    setState(() {
      _activities = activities;
      _notes = notes;
      _weeklyUnits = weeklyUnits;
      _loading = false;
    });
  }

  Future<void> _addActivity() async {
    final title = _activityController.text.trim();
    if (title.isEmpty) return;

    await _database.addActivity(widget.challenge.id!, title);
    _activityController.clear();
    await _loadData();
  }

  Future<void> _toggleActivity(ActivityRecord activity, bool completed) async {
    await _database.setActivityCompleted(activity.id, completed);

    final logs = await _database.getProgressLogs(widget.challenge.id!);
    final marker = 'activity:${activity.id}';

    if (completed) {
      await _database.addProgressLog(
        ProgressLogRecord(
          challengeId: widget.challenge.id!,
          loggedAt: DateTime.now(),
          units: 1,
          note: marker,
        ),
      );
    } else {
      final matchingLogs = logs.where((log) => log.note == marker).toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

      if (matchingLogs.isNotEmpty && matchingLogs.first.id != null) {
        await _database.deleteProgressLog(matchingLogs.first.id!);
      }
    }

    await _loadData();
  }

  Future<void> _addNote() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;

    await _database.addNote(widget.challenge.id!, note);
    _noteController.clear();
    await _loadData();
  }

  Future<void> _deleteNote(int id) async {
    await _database.deleteNote(id);
    await _loadData();
  }

  @override
  void dispose() {
    _activityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final progress = challenge.targetUnits == 0
        ? 0.0
        : (_weeklyUnits / challenge.targetUnits).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(challenge.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  challenge.category,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (challenge.description.isNotEmpty)
                  Text(challenge.description),
                const SizedBox(height: 20),
                Text(
                  'Weekly progress: $_weeklyUnits / '
                  '${challenge.targetUnits}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 24),
                Text(
                  'Activities',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _activityController,
                        decoration: const InputDecoration(
                          labelText: 'New activity',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addActivity(),
                      ),
                    ),
                    IconButton(
                      onPressed: _addActivity,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                ..._activities.map(
                  (activity) => CheckboxListTile(
                    value: activity.isCompleted,
                    title: Text(activity.title),
                    onChanged: (value) {
                      _toggleActivity(activity, value ?? false);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Write a note',
                    border: OutlineInputBorder(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _addNote,
                    child: const Text('Save Note'),
                  ),
                ),
                ..._notes.map(
                  (note) => Card(
                    child: ListTile(
                      title: Text(note.note),
                      subtitle: Text(
                        note.createdAt.toLocal().toString(),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteNote(note.id),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}