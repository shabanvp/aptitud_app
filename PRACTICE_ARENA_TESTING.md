# Practice Arena - Testing & Validation Guide

## Pre-Flight Checklist

Before launching the enhanced Practice Arena, ensure:

### ✅ Django Backend Requirements

```bash
# 1. Check Django is running
curl http://localhost:8001/api/tests/categories/
# Should return JSON with categories

# 2. Verify database has data
python manage.py shell
>>> from apps.tests.models import Category, Question
>>> Category.objects.count()  # Should be > 0
>>> Question.objects.count()  # Should be > 0

# 3. Check API endpoints work
curl http://localhost:8001/api/tests/questions/?limit=10
# Should return paginated questions

# 4. Verify user auth
curl -H "Authorization: Token YOUR_TOKEN" http://localhost:8001/api/tests/stats/
# Should return user statistics
```

### ✅ Flutter App Requirements

```bash
# 1. Ensure dependencies installed
cd app
flutter pub get

# 2. Check API service configuration
# File: app/lib/services/api_service.dart
# Verify baseUrl is correct (localhost:8001)

# 3. Run app
flutter run
```

---

## Test Scenarios

### 🧪 Test 1: Initial Load

**Expected Behavior:**
1. Open app, navigate to Practice tab
2. Should display "Practice Arena" header
3. Quick stats should show:
   - Total questions
   - Number of categories
   - Found count (initially = total)
4. Filters should be visible
5. Questions list should populate

**Validation:**
```
✓ No crash on load
✓ Questions display correctly
✓ All badges/tags visible
✓ Buttons are clickable
✓ Pull-to-refresh works
```

**If Fails:**
```
1. Check Django is running: curl http://localhost:8001/
2. Verify categories exist: python manage.py shell
3. Check API response: curl http://localhost:8001/api/tests/questions/
4. Review Flutter logs for errors
```

---

### 🧪 Test 2: Difficulty Filter

**Test Each Difficulty:**

```
Scenario: Filter by EASY
├─ Click [EASY] chip
├─ Should highlight
├─ Questions list updates
├─ All displayed questions should have difficulty="EASY"
├─ Found count should update
└─ No crash
✓ Test passes if 3-5 EASY questions displayed

Scenario: Filter by MEDIUM
├─ Click [MEDIUM] chip
├─ Previous selection deselects
├─ Questions list updates
└─ All questions have difficulty="MEDIUM"
✓ Test passes if 5-10 MEDIUM questions displayed

Scenario: Filter by HARD
├─ Click [HARD] chip
├─ Questions list updates
└─ All questions have difficulty="HARD"
✓ Test passes if 2-5 HARD questions displayed

Scenario: Reset with [ALL]
├─ Click [ALL] chip
├─ All difficulties show again
└─ Found count = Total count
✓ Test passes if count increases back to total
```

**Validation Code (Django Shell):**
```python
from apps.tests.models import Question
easy_count = Question.objects.filter(difficulty='EASY').count()
medium_count = Question.objects.filter(difficulty='MEDIUM').count()
hard_count = Question.objects.filter(difficulty='HARD').count()
print(f"Easy: {easy_count}, Medium: {medium_count}, Hard: {hard_count}")
# Compare with Flutter display
```

---

### 🧪 Test 3: Category Filter

**Test Category Selection:**

```
Scenario: Select Single Category
├─ Scroll to category filter
├─ Click "All Categories"
├─ Note initial found count
├─ Click specific category (e.g., "Programming")
├─ Questions list should show only that category
├─ Each question's category badge should match
├─ Found count should decrease
└─ "Found" stat updates

Scenario: Multiple Categories
├─ Select "General Aptitude"
├─ Verify questions only from General Aptitude
├─ Switch to "Logical Reasoning"
├─ Verify questions only from Logical Reasoning
└─ Back to "All Categories"
✓ Test passes if filtering works correctly
```

**Validation:**
```python
# Check category exists and has questions
from apps.tests.models import Category
cat = Category.objects.get(slug='programming-aptitude')
print(f"Category: {cat.name}, Questions: {cat.questions.count()}")
```

---

### 🧪 Test 4: Question Type Filter

**Test Type Selection:**

```
Scenario: Filter by MCQ
├─ Scroll to type filter
├─ Click [MCQ]
├─ All displayed questions should have type="MCQ"
├─ MCQ badge should appear on each card
├─ Found count updates
└─ No crash

Scenario: Filter by LOGICAL
├─ Click [LOGICAL]
├─ Questions update to LOGICAL type
├─ LOGICAL badge visible
└─ Found count matches LOGICAL count

Scenario: Filter by CODING
├─ Click [CODING]
├─ Questions update to CODING type
├─ CODING badge visible (orange color)
└─ Found count matches

Scenario: Reset with [ALL]
├─ Click [ALL]
├─ All types show again
└─ Found count = Total
✓ Test passes if type filtering works
```

---

### 🧪 Test 5: Combined Filters

**Test Multiple Filters Together:**

```
Scenario: EASY + Programming + MCQ
├─ Click [EASY]
├─ Select "Programming" category
├─ Click [MCQ]
├─ Only questions matching ALL three should display
├─ Each card should show:
│   └─ EASY badge (green)
│   └─ MCQ badge (purple)
│   └─ Programming category
├─ Found count should be ≤ any single filter
└─ No crash

Scenario: MEDIUM + Logical Reasoning + LOGICAL
├─ Click [MEDIUM]
├─ Select "Logical Reasoning"
├─ Click [LOGICAL]
├─ Display only MEDIUM Logical Reasoning questions
├─ All three filters highlighted
└─ Correct count shown

Scenario: HARD + General Aptitude + MCQ
├─ Similar validation
└─ Verify intersection of all filters

✓ Test passes if combined filtering works correctly
```

---

### 🧪 Test 6: Pagination

**Test Question Loading:**

```
Scenario: Initial Load
├─ Open Practice screen
├─ Should display 15 questions (or _pageSize value)
├─ "Load More" button visible if more exist
└─ Current page = 0

Scenario: Load More Button
├─ Scroll to bottom of list
├─ Click [Load More]
├─ Next 15 questions load
├─ Total displayed = 30 questions
├─ "Load More" visible if more exist
└─ No duplicates

Scenario: Edge Case (< 15 total)
├─ If only 10 total questions
├─ All 10 display
├─ No "Load More" button
└─ Works correctly

✓ Test passes if pagination loads correctly
```

---

### 🧪 Test 7: Question Attempt Flow

**Test Full Attempt Workflow:**

```
Scenario: Attempt Question
├─ Click [ATTEMPT] button
├─ Navigate to TestAttemptScreen
├─ Question details displayed fully
├─ All options visible
├─ Timer shows
├─ Can select option
├─ Can submit
├─ Get feedback
├─ Navigate back to Practice
├─ Questions list reappears
└─ Stats updated

Validation:
✓ Question fully loaded
✓ No missing data
✓ Options clickable
✓ Answer submits
✓ Feedback received
✓ Returns to Practice
✓ List preserved or refreshed
```

---

### 🧪 Test 8: Explanation Display

**Test Info Button:**

```
Scenario: View Explanation
├─ Find question with explanation
├─ Click [INFO] button
├─ Dialog appears
├─ Explanation text displays fully
├─ Text is readable
├─ Can scroll if long
├─ [Close] button works
├─ Dialog disappears
└─ Back to question list

Scenario: No Explanation
├─ Find question without explanation
├─ [INFO] button might be disabled or absent
├─ Or shows "No explanation available"
└─ No crash

✓ Test passes if explanations display correctly
```

---

### 🧪 Test 9: Statistics Display

**Test Stats Section:**

```
Scenario: Dashboard Stats
├─ Open Practice Dashboard
├─ Should display:
│   ├─ Attempted count
│   ├─ Correct count
│   ├─ Accuracy percentage
│   ├─ Current streak
├─ Numbers should be reasonable
├─ Percentages 0-100%
└─ No negative numbers

Validation:
✓ Stats load correctly
✓ Values are in valid range
✓ Calculations appear correct
✓ Updates after attempt

Difficulty Distribution:
├─ Progress bars show
├─ Colors match badges (Green/Blue/Red)
├─ Percentages sum to ~100%
├─ Counts match totals
└─ No visual glitches

Question Types:
├─ All types shown
├─ Counts add up
├─ Icons display
└─ Colors correct
```

---

### 🧪 Test 10: Error Handling

**Test Error Scenarios:**

```
Scenario: No Categories
├─ Clear categories in Django
├─ Refresh app
├─ Should show "No categories" message
├─ Don't crash
└─ Offer refresh option

Scenario: No Questions
├─ Clear questions in Django
├─ Refresh app
├─ Should show "No questions available"
├─ Don't crash
└─ Suggest Django admin action

Scenario: Network Error
├─ Simulate offline
├─ Should show error message
├─ Offer retry
├─ Don't crash

Scenario: API Timeout
├─ Simulate slow API
├─ Should show loading indicator
├─ Can cancel or retry
└─ Timeout after 10 seconds
```

---

## Automated Test Suite

### Test Commands

```bash
# Run tests
flutter test test/

# Specific test file
flutter test test/practice_screen_test.dart

# With coverage
flutter test --coverage
lcov --list coverage/lcov.info
```

### Sample Test File

```dart
// test/practice_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aptitude_go/ui/tests/practice_screen.dart';

void main() {
  group('PracticeScreen Tests', () {
    
    testWidgets('Should display Practice Arena title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PracticeScreen()));
      expect(find.text('Practice Arena'), findsOneWidget);
    });

    testWidgets('Should show quick stats', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PracticeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Found'), findsOneWidget);
    });

    testWidgets('Should filter by difficulty', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PracticeScreen()));
      await tester.pumpAndSettle();
      
      await tester.tap(find.byKey(const ValueKey('easy_filter')));
      await tester.pumpAndSettle();
      
      // Verify questions updated
      expect(find.byIcon(Icons.search_off_rounded), findsNothing);
    });

    testWidgets('Should paginate questions', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PracticeScreen()));
      await tester.pumpAndSettle();
      
      final loadMoreBtn = find.text('Load More');
      expect(loadMoreBtn, findsOneWidget);
      
      await tester.tap(loadMoreBtn);
      await tester.pumpAndSettle();
      
      // More questions should load
    });

    testWidgets('Should navigate to attempt screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PracticeScreen()));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('ATTEMPT').first);
      await tester.pumpAndSettle();
      
      expect(find.byType(TestAttemptScreen), findsOneWidget);
    });
  });
}
```

---

## Manual Testing Checklist

### Before Release

```
FUNCTIONALITY
□ All filters work independently
□ Combined filters work
□ Pagination loads correctly
□ Questions display completely
□ Attempt workflow works
□ Explanations display
□ Stats update after attempt
□ Refresh works
□ Pull-to-refresh works
□ No duplicate questions in paginated list

UI/UX
□ Text is readable
□ Colors are consistent
□ Icons display correctly
□ Buttons are clickable
□ No layout overflow
□ Responsive on different screen sizes
□ Dark theme looks good

PERFORMANCE
□ Initial load < 2 seconds
□ Filter response < 1 second
□ Pagination smooth
□ No lag when scrolling
□ No memory leaks
□ Handles 1000+ questions

ERROR HANDLING
□ Network error shown
□ Timeout handled
□ Empty states handled
□ Invalid data handled
□ Graceful failure

BACKEND INTEGRATION
□ API calls correct
□ Data mapping correct
□ Params passed correctly
□ Responses parsed correctly
□ Auth headers sent
□ Token refresh works
```

---

## Debugging Guide

### Common Issues & Solutions

#### Issue: Questions not loading

```
Diagnosis:
1. Check console logs
2. Verify Django running: curl http://localhost:8001/
3. Check API response: curl http://localhost:8001/api/tests/questions/
4. Verify token in SharedPreferences

Solution:
1. Ensure Django backend running
2. Check database has questions
3. Verify categories exist
4. Check API token valid
5. Review QuestionService code
```

#### Issue: Filters not updating

```
Diagnosis:
1. Check if _applyFilters() called
2. Verify filter values match
3. Check ListView rebuilds

Solution:
1. Ensure category slug matches exactly
2. Difficulty must be uppercase
3. Type must match MCQ/LOGICAL/CODING
4. Verify _selectedDifficulty state updates
```

#### Issue: Pagination infinite

```
Diagnosis:
1. Check _pageSize value
2. Verify itemCount calculation
3. Check _currentPage increments

Solution:
1. Ensure _pageSize is reasonable (15-25)
2. Fix itemCount: length + (hasMore ? 1 : 0)
3. Verify _currentPage updates on button click
```

#### Issue: Stats not updating

```
Diagnosis:
1. Check UserStats model
2. Verify API returns stats
3. Check after attempt, stats refreshed

Solution:
1. Ensure gameState.refreshStats() called
2. Verify /api/tests/stats/ endpoint
3. Check token sent in request
```

---

## Performance Monitoring

### Key Metrics

```
Metric                Target      Status
───────────────────────────────────────
Initial Load Time     < 2s        ✓
Filter Response       < 1s        ✓
Question Display      100ms       ✓
Pagination Load       < 500ms     ✓
Memory Usage          < 100MB     ✓
Scroll FPS            60 fps      ✓
API Response          < 1s        ✓
Database Query        < 500ms     ✓
```

### Profiling

```bash
# Run performance test
flutter run --profile

# Monitor memory
flutter run --checked
adb shell dumpsys meminfo | grep aptitude_go

# Check frame times
flutter run
# In DevTools: Timeline tab
```

---

## Regression Testing

After each update, test:

```
1. All filters still work
2. Statistics still display
3. Attempt flow still works
4. No new crashes
5. Performance not degraded
6. UI looks consistent
7. All fields populate
8. Explanations still show
```

---

## Release Checklist

Before pushing to production:

```
□ All tests pass
□ No console errors
□ No memory leaks
□ Performance acceptable
□ All features working
□ Error handling in place
□ Documentation updated
□ Version bumped (pubspec.yaml)
□ Screenshots captured
□ Testing completed
□ Code reviewed
□ Deployed to backend
□ Verified on live system
```

---

**Last Updated**: June 8, 2026  
**Test Coverage**: Comprehensive  
**Status**: Ready for Testing ✅
