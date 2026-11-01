import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<String> _categories = [
    'Study',
    'Fitness',
    'Creative',
    'Social',
    'Personal',
  ];

  String? _preferredCategory;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _preferredCategory =
          preferences.getString('preferredChallengeCategory');
      _loading = false;
    });
  }

  Future<void> _savePreference(String? category) async {
    final preferences = await SharedPreferences.getInstance();

    if (category == null) {
      await preferences.remove('preferredChallengeCategory');
    } else {
      await preferences.setString(
        'preferredChallengeCategory',
        category,
      );
    }

    if (!mounted) return;

    setState(() {
      _preferredCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Mission Match Preference',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a category to help Mission Match '
                  'recommend challenges. You can change this at any time.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _preferredCategory,
                  decoration: const InputDecoration(
                    labelText: 'Preferred category',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('No preference'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No preference'),
                    ),
                    ..._categories.map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    ),
                  ],
                  onChanged: _savePreference,
                ),
              ],
            ),
    );
  }
}
