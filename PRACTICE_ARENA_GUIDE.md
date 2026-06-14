# Enhanced Practice Arena - Implementation Guide

## Overview

The Practice Arena has been enhanced to provide a fully functional, well-organized interface that aligns with your Django project workflow. The new system includes:

✅ **Multi-level Organization**: Categories → Difficulties → Question Types
✅ **Advanced Filtering**: By difficulty, category, and question type
✅ **Progress Tracking**: User stats, accuracy, and streaks
✅ **Django Workflow Integration**: Mirrors backend categories and question structure
✅ **Pagination & Performance**: Efficient data loading with pagination support
✅ **Comprehensive Sections**: MCQ, Logical Reasoning, Coding, etc.

---

## Screen Architecture

### 1. **Practice Screen** (`practice_screen.dart`)
Main hub with all filtering and browsing capabilities.

**Features:**
- Real-time question filtering by:
  - Difficulty (EASY, MEDIUM, HARD)
  - Category (General Aptitude, Programming, etc.)
  - Question Type (MCQ, LOGICAL, CODING)
- Quick statistics:
  - Total questions available
  - Number of categories
  - Filtered results count
- Paginated question list with:
  - Difficulty and type badges
  - Category tags
  - Time limit indicators
  - Options preview
  - "Attempt" and "Info" (explanation) buttons
- Search and filter chips for quick navigation

**Key Methods:**
```dart
_applyFilters()        // Applies all active filters
_getPaginatedQuestions() // Returns paginated subset
_difficultyColor()     // Color coding for difficulty
_typeColor()           // Color coding for question type
```

**Data Flow:**
```
QuestionService.fetchCategories()
QuestionService.fetchQuestions(limit: 100)
↓
Filter & Organize
↓
Display with Pagination
```

---

### 2. **Practice Dashboard Screen** (`practice_dashboard_screen.dart`)
Comprehensive overview with user statistics and quick access.

**Sections:**
1. **User Progress**: Attempted, Correct, Accuracy %, Current Streak
2. **Quick Access**: All Questions, By Difficulty
3. **Difficulty Distribution**: Visual breakdown (Easy/Medium/Hard)
4. **Question Types**: MCQ, Logical, Coding counts
5. **Practice by Category**: Full category list with question counts

**Purpose:** Entry point for users who want an overview before diving into practice.

---

### 3. **Category Practice Screen** (`category_practice_screen.dart`)
Focused practice within a single category.

**Features:**
- Difficulty filter (All/Easy/Medium/Hard)
- Question list specific to category
- Direct attempt interface
- Category metadata display

---

## Django Backend Integration

### Models Sync

The Flutter app mirrors Django models:

```
Django Backend          →    Flutter App
─────────────────────────────────────────
Category Model         →    Category class
  - id, name, slug            - Complete mapping
  - description
  - question_count

Question Model         →    Question class
  - id, text, category        - Complete with options
  - difficulty                - Type categorization
  - question_type
  - time_limit
  - explanation

Option Model           →    QuestionOption class
  - id, text, is_correct      - Full serialization
```

### API Endpoints Used

```
GET  /api/tests/categories/
     Returns: { categories: [...] }
     Maps to: QuestionService.fetchCategories()

GET  /api/tests/questions/?limit=X&offset=Y&category=slug&difficulty=level
     Returns: { questions: [...], total: N }
     Maps to: QuestionService.fetchQuestions/fetchQuestionsPaged()

POST /api/tests/submit/
     Body: { question_id, selected_option_id, daily_challenge }
     Maps to: QuestionService.submitAnswer()

GET  /api/tests/stats/
     Returns: { attempted, correct, accuracy, streak }
     Maps to: QuestionService.fetchUserStats()
```

---

## Filter Logic Implementation

### Difficulty Classification
```dart
'EASY'    → Green (#22C55E) - Foundational
'MEDIUM'  → Blue (#3B82F6) - Standard
'HARD'    → Red (#EF4444) - Advanced
```

### Question Type Classification
```dart
'MCQ'      → Primary color (#8B5CF6)
'LOGICAL'  → Purple (#9C27B0)
'CODING'   → Orange (#FF9800)
```

### Category Organization
Follows Django's category structure:

**Core Aptitude Categories:**
- General Aptitude
- Logical Reasoning
- Quantitative Aptitude
- Verbal Ability
- Computer Fundamentals
- Programming Aptitude
- Debugging & Code Logic
- Cognitive Ability
- Memory & Attention

**Company-Specific Categories:**
- All company question banks
- Automatically imported from Django

---

## Data Models

### Dart Models Alignment

```dart
class Category {
  final int id;
  final String name;
  final String slug;           // Matches Django slug
  final String description;
  final int questionCount;     // From Django's Q_count
}

class Question {
  final String id;
  final String text;
  final String category;       // Category name
  final String categorySlug;   // For filtering
  final String difficulty;     // EASY/MEDIUM/HARD
  final String type;           // MCQ/LOGICAL/CODING
  final List<QuestionOption> options;
  final int timeLimit;
  final String explanation;
}

class QuestionOption {
  final String id;
  final String text;
  final bool isCorrect;
}
```

---

## User Flow

### 1. **Landing on Practice Arena**
```
User clicks "Practice" tab
  ↓
PracticeScreen loads with all filtering options
  ↓
QuestionService.fetchQuestions() fetches up to 100 questions
  ↓
Display statistics and filter chips
```

### 2. **Browsing Questions**
```
User applies filters (Difficulty/Category/Type)
  ↓
_applyFilters() processes selections
  ↓
_filteredQuestions list is updated
  ↓
ListView rebuilds with matching questions
```

### 3. **Attempting a Question**
```
User clicks "ATTEMPT" button
  ↓
Navigate to TestAttemptScreen with Question object
  ↓
Display full question with all options
  ↓
User selects answer and submits
  ↓
QuestionService.submitAnswer() called
  ↓
Return to PracticeScreen and refresh stats
```

### 4. **Viewing Explanation**
```
User clicks "INFO" button
  ↓
showDialog() displays explanation
  ↓
User reviews and closes
```

---

## State Management

### Provider Integration

**GameStateProvider** manages:
- User stats (coins, lives, level, exp)
- Attempt history
- Current streak
- Performance metrics

**AuthProvider** manages:
- User authentication
- User metadata
- Company flag (determines candidate vs company view)

### Data Refresh
```dart
// After attempting a question
await gameState.refreshStats();
_loadData();  // Refresh question list
```

---

## Performance Optimizations

1. **Pagination**: Load 15 questions per page (configurable via `_pageSize`)
2. **Lazy Loading**: Categories loaded on-demand
3. **Efficient Filtering**: In-memory filtering (no extra API calls)
4. **Cached Categories**: Fetched once per session
5. **Smart Rebuilds**: Only setState() when necessary

---

## Statistics Displayed

### Per-Session Stats
- **Total Questions**: All available questions
- **Total Categories**: Number of aptitude areas
- **Filtered Count**: Results matching current filters

### User Progress (if available)
- **Attempted**: Total questions tried
- **Correct**: Total correct answers
- **Accuracy %**: Percentage correct
- **Current Streak**: Consecutive correct answers

### Difficulty Distribution
- Visual progress bars for each level
- Percentage breakdown
- Question counts per difficulty

### By Type
- Card grid showing question type distribution
- Direct navigation options

---

## Integration Checklist

- [x] QuestionService integration
- [x] Advanced filtering system
- [x] Pagination support
- [x] Statistics display
- [x] Category browsing
- [x] Question type organization
- [x] Attempt workflow
- [x] Explanation display
- [x] Provider integration
- [x] Error handling
- [x] Loading states
- [x] Empty states
- [x] Refresh functionality

---

## Customization Guide

### Change Pagination Size
```dart
// In practice_screen.dart
final int _pageSize = 15;  // Change to 20, 25, etc.
```

### Add New Question Type
```dart
// In _typeColor() method
case 'NEW_TYPE': return const Color(0xABCDEF);

// In _types list
final List<String> _types = ['ALL', 'MCQ', 'LOGICAL', 'CODING', 'NEW_TYPE'];
```

### Modify Colors
All colors reference `AppTheme` constants from `core/theme.dart`:
```dart
AppTheme.primary
AppTheme.secondary
AppTheme.accent
AppTheme.error
AppTheme.surface
```

---

## API Response Examples

### Categories Response
```json
{
  "categories": [
    {
      "id": 1,
      "name": "General Aptitude",
      "slug": "general-aptitude",
      "description": "Basic aptitude...",
      "question_count": 150
    },
    ...
  ]
}
```

### Questions Response
```json
{
  "questions": [
    {
      "id": "123",
      "text": "What is...",
      "category": "Programming",
      "category_slug": "programming-aptitude",
      "difficulty": "MEDIUM",
      "question_type": "MCQ",
      "time_limit": 60,
      "explanation": "The answer is...",
      "options": [
        {
          "id": "opt1",
          "text": "Option A",
          "is_correct": true
        },
        ...
      ]
    },
    ...
  ],
  "total": 2500
}
```

---

## Testing Checklist

- [ ] Filter by single difficulty level
- [ ] Filter by single category
- [ ] Filter by single question type
- [ ] Combine multiple filters
- [ ] Reset all filters
- [ ] Pagination loading
- [ ] Attempt question flow
- [ ] View explanation
- [ ] Refresh data
- [ ] Empty state handling
- [ ] Error state handling
- [ ] Stats update after attempt

---

## Future Enhancements

1. **Bookmarking**: Save favorite questions
2. **Timed Practice**: Full tests within time limit
3. **Performance Analytics**: Detailed statistics per category
4. **Recommendations**: AI-suggested questions based on weak areas
5. **Offline Mode**: Downloaded question sets
6. **Custom Tests**: Create practice tests from selected questions
7. **Difficulty Progression**: Auto-adjust based on performance
8. **Social Sharing**: Share achievements and statistics

---

## Support & Troubleshooting

**Issue: Questions not loading**
- Check API endpoint: `/api/tests/questions/`
- Verify QuestionService in `services/question_service.dart`
- Check Django backend is running on port 8001

**Issue: Filters not working**
- Verify categorySlug matches Django slug exactly
- Check difficulty values are EASY/MEDIUM/HARD (uppercase)
- Ensure question type matches MCQ/LOGICAL/CODING

**Issue: Stats not updating**
- Call `gameState.refreshStats()` after attempt
- Verify UserStats API endpoint returns correct data

---

## File Structure

```
app/lib/
├── ui/tests/
│   ├── practice_screen.dart                    ← Main arena
│   ├── practice_dashboard_screen.dart          ← Overview dashboard
│   ├── category_practice_screen.dart           ← Category-specific
│   └── test_attempt_screen.dart                ← Question attempt
├── services/
│   └── question_service.dart                   ← All API calls
├── models/
│   └── question.dart                           ← Data models
└── providers/
    └── game_state_provider.dart                ← State management
```

---

**Version**: 1.0.0  
**Last Updated**: 2026-06-08  
**Django Workflow**: Fully Aligned ✅
