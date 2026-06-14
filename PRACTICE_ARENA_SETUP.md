# Practice Arena - Integration & Setup Guide

## Quick Start

The enhanced Practice Arena is **fully integrated** into your Flutter app. Here's what's available:

### Two Main Entry Points:

#### 1. **PracticeScreen** (Default - Current Tab)
- **File**: `app/lib/ui/tests/practice_screen.dart`
- **Access**: Click "Practice" tab in bottom navigation
- **Best For**: Users who want to browse all questions with advanced filtering
- **Features**: 
  - Difficulty filter (Easy, Medium, Hard)
  - Category filter
  - Question type filter
  - Pagination
  - Full question details with explanations

#### 2. **PracticeDashboardScreen** (Optional - Overview)
- **File**: `app/lib/ui/tests/practice_dashboard_screen.dart`
- **Best For**: First-time users or overview seekers
- **Features**:
  - User progress statistics
  - Difficulty distribution charts
  - Question type breakdown
  - Category browser with counts

---

## Option 1: Use Current Practice Screen (Already Active)

### Current Navigation Setup
```dart
// app/lib/ui/dashboard/dashboard_screen.dart
static const List<Widget> _candidateScreens = [
  HomeScreen(),
  PracticeScreen(),        // ← Already your Practice tab
  MultiplayerScreen(),
  StoreScreen(),
];
```

**No changes needed!** The enhanced `PracticeScreen` is already integrated.

---

## Option 2: Make Dashboard the Default Practice Tab

### Steps to Implement:

1. **Open** `app/lib/ui/dashboard/dashboard_screen.dart`

2. **Replace the import** (line ~8):
```dart
// OLD:
import '../tests/practice_screen.dart';

// NEW:
import '../tests/practice_dashboard_screen.dart';
```

3. **Update the screens list** (line ~26):
```dart
// OLD:
static const List<Widget> _candidateScreens = [
  HomeScreen(),
  PracticeScreen(),
  MultiplayerScreen(),
  StoreScreen(),
];

// NEW:
static const List<Widget> _candidateScreens = [
  HomeScreen(),
  PracticeDashboardScreen(),
  MultiplayerScreen(),
  StoreScreen(),
];
```

4. **Done!** Now the dashboard will be the Practice tab

---

## Option 3: Two-Tab Practice System

Keep both screens accessible via sub-navigation:

```dart
// In practice_dashboard_screen.dart, add action button:
ElevatedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PracticeScreen()),
  ),
  icon: const Icon(Icons.quiz_rounded),
  label: const Text('All Questions'),
),
```

---

## Features Implemented

### 🎯 Smart Filtering
- **Difficulty**: Easy, Medium, Hard
- **Category**: All aptitude categories from Django
- **Type**: MCQ, Logical, Coding
- **Combined Filters**: Use any combination

### 📊 Statistics
- Questions attempted
- Correct answers
- Accuracy percentage
- Current streak
- Difficulty distribution
- Type breakdown

### 🔍 Question Details
- Full question text
- All options preview
- Time limit
- Difficulty badge
- Question type
- Category tag
- Explanation access

### ⚡ Performance
- Pagination (15 questions per page)
- Instant filtering (no API calls)
- Refresh functionality
- Error handling
- Loading states

### 🎨 UI/UX
- Dark theme optimized
- Color-coded badges
- Progress bars
- Stat cards
- Responsive design

---

## API Integration

All data comes from these Django endpoints:

```
GET /api/tests/categories/
   └─ Lists all categories with question counts

GET /api/tests/questions/?limit=100&offset=0
   └─ Fetches questions (paginated)
   
Optional filters:
   &category=slug        → Filter by category slug
   &difficulty=MEDIUM    → Filter by difficulty
```

**Service Methods Used:**
```dart
QuestionService.fetchCategories()
QuestionService.fetchQuestions(limit, categorySlug, difficulty)
QuestionService.fetchUserStats()
QuestionService.submitAnswer(questionId, selectedOptionId)
```

---

## Customization

### Change Page Size
```dart
// app/lib/ui/tests/practice_screen.dart, line ~27
final int _pageSize = 15;  // Change to 20, 25, 50, etc.
```

### Modify Filter Options
```dart
// Add new question type
final List<String> _types = ['ALL', 'MCQ', 'LOGICAL', 'CODING', 'YOUR_TYPE'];

// Add custom color for it
case 'YOUR_TYPE': return const Color(0xFF123456);
```

### Adjust Color Scheme
```dart
// app/lib/core/theme.dart
static const Color primary = Color(0xFF8B5CF6);
static const Color secondary = Color(0xFF22C55E);
static const Color accent = Color(0xFF3B82F6);
static const Color error = Color(0xFFEF4444);
```

---

## Testing the Integration

### 1. Test Question Loading
- Run app, go to Practice tab
- Should see questions if any exist in Django
- If empty: "No questions available" message

### 2. Test Filtering
```
Try each filter individually:
- Difficulty: Easy, Medium, Hard
- Category: Select different categories
- Type: MCQ, Logical, Coding

Then combine filters:
- Easy + Programming
- Medium + Logical Reasoning
- Hard + Coding
```

### 3. Test Question Attempt
- Click ATTEMPT button
- Should navigate to TestAttemptScreen
- After submission, should refresh practice list

### 4. Test Info Display
- Click INFO button on questions with explanations
- Should show explanation dialog
- Should be readable and formatted

### 5. Test Pagination
- Scroll to bottom of list
- Click "Load More" if available
- Should load next 15 questions

### 6. Test Refresh
- Pull down to refresh
- Should reload all questions
- Filters should persist

---

## Troubleshooting

### Questions Not Showing?
1. Verify Django backend is running:
   ```bash
   python manage.py runserver 0.0.0.0:8001
   ```

2. Check API endpoint works:
   ```bash
   curl http://localhost:8001/api/tests/questions/
   ```

3. Verify categories exist in Django admin
4. Check if questions are associated with categories

### Filters Not Working?
1. Ensure question type exactly matches: MCQ, LOGICAL, CODING
2. Difficulty must be: EASY, MEDIUM, HARD
3. Category slug must match Django exactly

### Stats Not Showing?
1. Check `/api/tests/stats/` endpoint responds
2. Verify user is authenticated
3. User must have attempted at least one question

### Performance Issues?
1. Reduce `_pageSize` from 15 to 10
2. Remove some categories from display
3. Limit questions fetched from 100 to 50

---

## Architecture Overview

```
user input
    ↓
PracticeScreen
    ├─→ _applyFilters()
    ├─→ _difficultyColor() / _typeColor()
    └─→ _getPaginatedQuestions()
    ↓
QuestionService
    ├─→ fetchCategories()
    ├─→ fetchQuestions()
    └─→ fetchUserStats()
    ↓
API Endpoints
    ├─→ /api/tests/categories/
    ├─→ /api/tests/questions/
    └─→ /api/tests/stats/
    ↓
Django Backend
    ├─→ Category Model
    ├─→ Question Model
    └─→ User Stats
```

---

## Data Flow Example

### User filters by "MEDIUM" difficulty + "Programming" category:

```
1. User selects filters
   _selectedDifficulty = "MEDIUM"
   _selectedCategory = "programming-aptitude"

2. _applyFilters() called:
   _filteredQuestions = _allQuestions
     .where((q) => q.difficulty == "MEDIUM")
     .where((q) => q.categorySlug == "programming-aptitude")
     .toList()

3. UI rebuilds with filtered list

4. _getPaginatedQuestions() returns first 15 matching questions

5. ListView displays results with:
   - MEDIUM difficulty badge
   - Programming category tag
   - All options preview
   - ATTEMPT and INFO buttons
```

---

## Database Mapping

### Django → Flutter Sync

```
Django Category Model:
  ├─ id → Category.id
  ├─ name → Category.name
  ├─ slug → Category.slug (for filtering)
  ├─ description → Category.description
  └─ questions.count() → Category.questionCount

Django Question Model:
  ├─ id → Question.id
  ├─ text → Question.text
  ├─ category → Question.category (name)
  ├─ category.slug → Question.categorySlug (for filtering)
  ├─ difficulty → Question.difficulty (EASY/MEDIUM/HARD)
  ├─ question_type → Question.type (MCQ/LOGICAL/CODING)
  ├─ time_limit → Question.timeLimit
  ├─ explanation → Question.explanation
  └─ options → Question.options (list)

Django Option Model:
  ├─ id → QuestionOption.id
  ├─ text → QuestionOption.text
  └─ is_correct → QuestionOption.isCorrect
```

---

## Performance Tips

### For Large Datasets (1000+ questions)
1. Reduce initial fetch:
   ```dart
   // Change from
   final questions = await QuestionService.fetchQuestions(limit: 100);
   // To
   final questions = await QuestionService.fetchQuestions(limit: 50);
   ```

2. Implement lazy loading on scroll
3. Cache categories more aggressively

### For Slow Networks
1. Reduce page size to 10
2. Add timeout handling:
   ```dart
   try {
     // API call with 10s timeout
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Network error: $e')),
     );
   }
   ```

---

## Feature Roadmap

Currently Implemented ✅:
- [x] Category filtering
- [x] Difficulty filtering
- [x] Question type filtering
- [x] Combined filters
- [x] Pagination
- [x] Question details
- [x] Explanations
- [x] User statistics
- [x] Difficulty distribution
- [x] Type breakdown

Potential Additions:
- [ ] Search by keyword
- [ ] Timed practice tests
- [ ] Bookmarked questions
- [ ] Custom test creation
- [ ] Performance analytics
- [ ] Difficulty progression
- [ ] AI recommendations

---

## Support

For issues or questions:
1. Check PRACTICE_ARENA_GUIDE.md for detailed documentation
2. Verify Django backend is running
3. Check API endpoints respond correctly
4. Review Flutter logs for errors

---

**Last Updated**: June 8, 2026  
**Flutter Version**: 3.10.8+  
**Status**: Production Ready ✅
