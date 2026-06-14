import '../models/user.dart';
import '../models/question.dart';
import '../models/store_item.dart';
import '../models/event.dart';

class MockDataService {
  static final User currentUser = User.mockCandidate();

  static final List<StoreItem> storeItems = [
    StoreItem(id: '1', name: 'Golden Frame', description: 'A shiny golden frame for your avatar.', cost: 500, itemType: 'FRAME'),
    StoreItem(id: '2', name: 'Neon Theme', description: 'Cyberpunk neon background theme.', cost: 1200, itemType: 'THEME', minLevelRequired: 5),
    StoreItem(id: '3', name: 'Life Refill x5', description: 'Instantly refill 5 lives.', cost: 300, itemType: 'LIFE_REFILL'),
    StoreItem(id: '4', name: 'Ninja Avatar', description: 'Exclusive Ninja avatar.', cost: 800, itemType: 'AVATAR', minLevelRequired: 10),
  ];

  static final List<Question> sampleQuestions = [
    Question(
      id: '1',
      text: 'What is the next number in the sequence: 2, 4, 8, 16, ...?',
      category: 'Logical Reasoning',
      difficulty: 'EASY',
      type: 'LOGICAL',
      options: [
        QuestionOption(id: 'o1', text: '24'),
        QuestionOption(id: 'o2', text: '32', isCorrect: true),
        QuestionOption(id: 'o3', text: '64'),
        QuestionOption(id: 'o4', text: '20'),
      ],
    ),
    Question(
      id: '2',
      text: 'Which of the following is not a Dart keyword?',
      category: 'Programming',
      difficulty: 'MEDIUM',
      type: 'MCQ',
      options: [
        QuestionOption(id: 'o1', text: 'await'),
        QuestionOption(id: 'o2', text: 'yield'),
        QuestionOption(id: 'o3', text: 'export', isCorrect: true),
        QuestionOption(id: 'o4', text: 'factory'),
      ],
    ),
  ];

  static final List<Event> upcomingEvents = [
    Event(
      id: 'e1',
      title: 'TechCorp Software Engineering Challenge',
      recruiterId: '2',
      category: 'Programming',
      description: 'A 60-minute coding challenge for prospective SWE interns at TechCorp.',
      startTime: DateTime.now().add(const Duration(hours: 2)),
      endTime: DateTime.now().add(const Duration(hours: 4)),
      totalQuestions: 15,
      timeLimitSeconds: 3600,
    ),
  ];
}
