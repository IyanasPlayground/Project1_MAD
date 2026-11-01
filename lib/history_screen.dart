import 'package:flutter/material.dart';
import 'data/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _database = DatabaseHelper();

  late Future<List<ProgressLogRecord>> _logs;

  @override
  void initState() {
    super.initState();
    _logs = _database.getAllProgressLogs();
  }

  Future<void> _refresh() async {
    setState(() {
      _logs = _database.getAllProgressLogs();
    });
    await _logs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress History')),
      body: FutureBuilder<List<ProgressLogRecord>>(
        future: _logs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load history: ${snapshot.error}'),
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(
              child: Text('No progress has been recorded yet.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];

                return FutureBuilder<ChallengeRecord?>(
                  future: _database.getChallenge(log.challengeId),
                  builder: (context, challengeSnapshot) {
                    final challenge = challengeSnapshot.data;

                    return ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(
                        challenge?.title ?? 'Challenge ${log.challengeId}',
                      ),
                      subtitle: Text(
                        '${log.units} unit(s) • '
                        '${log.loggedAt.toLocal()}',
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}