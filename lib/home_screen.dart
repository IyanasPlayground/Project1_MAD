import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/database_helper.dart';
import 'mission_match.dart';
import 'create_edit_screen.dart';
import 'challenge_detail_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _database = DatabaseHelper();

  List<ChallengeRecord> _challenges = [];
  List<ProgressLogRecord> _progressLogs = [];
  String? _preferredCategory;

  bool _loading = true;
  bool _hideMissionMatch = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      var challenges = await _database.getAllChallenges();

      if (challenges.isEmpty) {
        await _addStarterChallenges();
        challenges = await _database.getAllChallenges();
      }

      final logs = await _database.getAllProgressLogs();
      final preferences = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _challenges = challenges;
        _progressLogs = logs;
        _preferredCategory =
            preferences.getString('preferredChallengeCategory');
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load challenges: $error')),
      );
    }
  }

  Future<void> _addStarterChallenges() async {
    final starters = [
      ChallengeRecord(
        title: 'Explore a New Study Spot',
        category: 'Study',
        targetUnits: 3,
        description: 'Find and try three different places to study.',
      ),
      ChallengeRecord(
        title: 'Practice a New Skill',
        category: 'Creative',
        targetUnits: 5,
        description: 'Spend time practicing a skill you want to improve.',
      ),
      ChallengeRecord(
        title: 'Take a Campus Break',
        category: 'Personal',
        targetUnits: 3,
        description: 'Take a few intentional breaks during your week.',
      ),
    ];

    for (final starter in starters) {
      final id = await _database.createChallenge(starter);

      if (starter.title == 'Explore a New Study Spot') {
        await _database.addActivity(id, 'Visit the library');
        await _database.addActivity(id, 'Try a quiet campus space');
        await _database.addActivity(id, 'Study in a new location');
      } else if (starter.title == 'Practice a New Skill') {
        await _database.addActivity(id, 'Choose a skill');
        await _database.addActivity(id, 'Practice for 15 minutes');
        await _database.addActivity(id, 'Practice again');
      } else {
        await _database.addActivity(id, 'Take a walk');
        await _database.addActivity(id, 'Take a screen break');
        await _database.addActivity(id, 'Relax without multitasking');
      }
    }
  }

  Future<void> _openCreateScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateChallengeScreen(),
      ),
    );

    if (result == true) {
      setState(() => _hideMissionMatch = false);
      await _loadData();
    }
  }

  Future<void> _openEditScreen(ChallengeRecord challenge) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateChallengeScreen(challenge: challenge),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _openDetails(ChallengeRecord challenge) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeDetailScreen(challenge: challenge),
      ),
    );

    await _loadData();
  }

  Future<void> _toggleChallenge(
    ChallengeRecord challenge,
    bool completed,
  ) async {
    await _database.setChallengeCompleted(challenge.id!, completed);
    await _loadData();
  }

  Future<void> _deleteChallenge(ChallengeRecord challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete challenge?'),
        content: Text('Delete "${challenge.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _database.deleteChallenge(challenge.id!);
      await _loadData();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This challenge has progress history and cannot be deleted.',
          ),
        ),
      );
    }
  }

  MissionMatchResult _getMissionMatchResult() {
    final challenges = _challenges
        .where((challenge) => challenge.id != null)
        .map(
          (challenge) => MissionMatchChallenge(
            id: challenge.id!,
            title: challenge.title,
            category: challenge.category,
            targetUnits: challenge.targetUnits,
          ),
        )
        .toList();

    final logs = _progressLogs
        .where((log) => log.id != null)
        .map(
          (log) => MissionMatchProgressLog(
            id: log.id!,
            challengeId: log.challengeId,
            loggedAt: log.loggedAt,
            units: log.units,
          ),
        )
        .toList();

    return MissionMatch.recommend(
      challenges: challenges,
      progressLogs: logs,
      preferredCategory: _preferredCategory,
    );
  }

  Widget _buildMissionMatchCard() {
    if (_hideMissionMatch) return const SizedBox.shrink();

    final result = _getMissionMatchResult();

    return MissionMatchSuggestionCard(
      result: result,
      onViewMission: (suggestion) {
        final challenge = _challenges.firstWhere(
          (item) => item.id == suggestion.id,
        );
        _openDetails(challenge);
      },
      onNotNow: () {
        setState(() => _hideMissionMatch = true);
      },
    );
  }

  Widget _buildChallengeCard(ChallengeRecord challenge) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: challenge.isCompleted,
                  onChanged: (value) {
                    _toggleChallenge(challenge, value ?? false);
                  },
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _openDetails(challenge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${challenge.category} • '
                          'Target: ${challenge.targetUnits}',
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEditScreen(challenge);
                    } else if (value == 'delete') {
                      _deleteChallenge(challenge);
                    } else if (value == 'details') {
                      _openDetails(challenge);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'details',
                      child: Text('View details'),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            if (challenge.description.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Text(challenge.description),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Your Mission Board',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Small challenges can help you make progress '
              'one step at a time.',
            ),
          ),
          _buildMissionMatchCard(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'My Challenges',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _openCreateScreen,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          if (_challenges.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No challenges yet. Add your first one!'),
              ),
            )
          else
            ..._challenges.map(_buildChallengeCard),
        ],
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );

    final preferences = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _preferredCategory =
          preferences.getString('preferredChallengeCategory');
      _hideMissionMatch = false;
    });
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Campus Challenge')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Challenge'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: _buildHomeContent(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);

          if (index == 1) {
            _openHistory();
          } else if (index == 2) {
            _openSettings();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}