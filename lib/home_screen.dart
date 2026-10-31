import 'package:flutter/material.dart';
import 'create_edit_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'challenge_detail_screen.dart';

void main() {
  runApp(const CampusApp());
}

class CampusApp extends StatelessWidget {
  const CampusApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Challenge',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
  home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  //only adding 5, for now at least 
  List<Challenge> challenges = [
    Challenge(
      'Challenge 1', 
      'Health', 
      false,
      activities: ['Take 3 pictures of all the things you find interesting', 'Share your pics'],
      description: 'Walk around the campus for 20 minutes and take a picture of 3 things you found interesting.',
    ),
    Challenge(
      'Challenge 2', 
      'Fun', 
      false,
      activities: ['Look on PIN to review clubs', 'Choose a club and RSVP'],
      description: 'Attend a student club meeting and take a photo.',
    ),
    Challenge(
      'Challenge 3', 
      'Wellness', 
      false,
      description: 'Spend 20 minutes meditating at the campus library quiet zone.',
    ),
    Challenge(
      'Challenge 4', 
      'Campus', 
      false,
      description: 'Visit the library and reserve a study room.',
    ),
    Challenge(
      'Challenge 5', 
      'Learning', 
      false,
      activities: ['Review your syllabus to find info on your proffessors office hours', 'Email your proffessor to inform them you are coming'],
      description: 'Attend a professors office hours.',
    ),
  ];

  void _addChallenge() async {
  final newChallenge = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const CreateChallengeScreen(),
    ),
  );

  if (newChallenge != null && newChallenge is Challenge) {
    setState(() {
      challenges.add(newChallenge);
    });
  }
}
  
  void _doneChallenge(int index) {
    setState(() {
      challenges[index].isCompleted = !challenges[index].isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    int completedCount = 0;
    int totalCount = challenges.length;
    double progressValue = 0.0;

    for (var challenge in challenges) {
      if (challenge.isCompleted == true) {
           completedCount++;
      }
    }

    if (totalCount > 0) {
      progressValue = completedCount / totalCount; } else {
      progressValue = 0.0;
    }


    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Campus Challenge',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateChallengeScreen(),
                  ),
                        );
                      },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.lightGreen,  
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: const [
                        Text(
                          'Hello!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ready to knock out some challenges?',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.wb_sunny_rounded,
                      color: Colors.amber,
                      size: 34,
             ),
            ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Challenge Score',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completedCount / $totalCount Challenges completed',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: Colors.white,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
               child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Active Challenges',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Icon(
                        Icons.menu_rounded,
                        color: Colors.blue,
                        size: 22,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextButton.icon(
                    onPressed: _addChallenge,
                    icon: const Icon(Icons.add),
                    label: const Text('Add a challenge'),
                  ),

                  const SizedBox(height: 12),

                  Column(
                    children: challenges.asMap().entries.map((entry) {
                      int index = entry.key;
                      Challenge challenge = entry.value;
                      bool isCompleted = challenge.isCompleted;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChallengeDetailScreen(challenge: challenge,
                                ),
                              ),
                            );
                            setState(() {});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white, 
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCompleted ? Colors.green : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _doneChallenge(index),
                                  child: Icon(
                                    isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                                    color: isCompleted ? Colors.green : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  challenge.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none, 
                                    color: isCompleted ? Colors.grey : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),  ),
                      );
                    }).toList(),
                  )
                ],
   ),),
    ],
        ),
      ),
    ),

// bottom menu to add all the pages 
  bottomNavigationBar: 
  Container(
  color: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      IconButton(
        icon: const Icon(Icons.home, size: 32),
        onPressed: () {

        },
      ),
      IconButton(
        icon: const Icon(Icons.access_time_outlined, size: 32),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoryScreen()),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.settings_outlined, size: 32),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        },
      ),
    ],
  ),
  ),
  );
  }
}
