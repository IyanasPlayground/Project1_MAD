import 'package:flutter/material.dart';
import 'data/database_helper.dart';

class CreateChallengeScreen extends StatefulWidget {
  final ChallengeRecord? challenge;

  const CreateChallengeScreen({super.key, this.challenge});

  @override
  State<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController(text: '1');
  final _activityController = TextEditingController();

  final DatabaseHelper _database = DatabaseHelper();

  String _category = 'Study';
  final List<String> _activities = [];
  bool _saving = false;

  final List<String> _categories = [
    'Study',
    'Fitness',
    'Creative',
    'Social',
    'Personal',
  ];

  @override
  void initState() {
    super.initState();

    final challenge = widget.challenge;

    if (challenge != null) {
      _titleController.text = challenge.title;
      _descriptionController.text = challenge.description;
      _targetController.text = challenge.targetUnits.toString();
      _category = challenge.category;
      _loadActivities(challenge.id!);
    }
  }

  Future<void> _loadActivities(int challengeId) async {
    final activities = await _database.getActivities(challengeId);

    if (!mounted) return;

    setState(() {
      _activities
        ..clear()
        ..addAll(activities.map((activity) => activity.title));
    });
  }

  void _addActivity() {
    final title = _activityController.text.trim();

    if (title.isEmpty) return;

    setState(() {
      _activities.add(title);
      _activityController.clear();
    });
  }

  Future<void> _saveChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final challenge = ChallengeRecord(
        id: widget.challenge?.id,
        title: _titleController.text.trim(),
        category: _category,
        targetUnits: int.parse(_targetController.text.trim()),
        description: _descriptionController.text.trim(),
        isCompleted: widget.challenge?.isCompleted ?? false,
      );

      int challengeId;

      if (widget.challenge == null) {
        challengeId = await _database.createChallenge(challenge);

        for (final activity in _activities) {
          await _database.addActivity(challengeId, activity);
        }
      } else {
        challengeId = widget.challenge!.id!;
        await _database.updateChallenge(challenge);

        final oldActivities =
            await _database.getActivities(challengeId);

        for (final activity in oldActivities) {
          await _database.deleteActivity(activity.id);
        }

        for (final activity in _activities) {
          await _database.addActivity(challengeId, activity);
        }
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save challenge: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.challenge != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Challenge' : 'Create Challenge'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Challenge title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a challenge title.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target units',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final number = int.tryParse(value ?? '');
                if (number == null || number < 1) {
                  return 'Enter a whole number greater than zero.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Activities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _activityController,
                    decoration: const InputDecoration(
                      labelText: 'Add an activity',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addActivity(),
                  ),
                ),
                IconButton(
                  onPressed: _addActivity,
                  icon: const Icon(Icons.add_circle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._activities.asMap().entries.map((entry) {
              return ListTile(
                title: Text(entry.value),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() => _activities.removeAt(entry.key));
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _saveChallenge,
              child: _saving
                  ? const CircularProgressIndicator()
                  : Text(isEditing ? 'Save Changes' : 'Create Challenge'),
            ),
          ],
        ),
      ),
    );
  }
}