import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/question.dart';
import '../../services/event_service.dart';
import '../../services/question_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _questionsController = TextEditingController(text: '10');
  final _durationController = TextEditingController(text: '10');
  final _thresholdController = TextEditingController(text: '50');

  List<Category> _categories = [];
  Category? _selectedCategory;
  String _thresholdType = 'TIME';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _startDate = DateTime.now().add(const Duration(minutes: 15));
    _endDate = DateTime.now().add(const Duration(hours: 1, minutes: 15));
  }

  Future<void> _loadCategories() async {
    final categories = await QuestionService.fetchCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
    }
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose both start and end date/time.')),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final response = await EventService.createEvent(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      totalQuestions: int.tryParse(_questionsController.text.trim()) ?? 10,
      timeLimitSeconds: (int.tryParse(_durationController.text.trim()) ?? 10) * 60,
      thresholdType: _thresholdType,
      thresholdValue: int.tryParse(_thresholdController.text.trim()) ?? 0,
      startTime: _startDate!.toUtc().toIso8601String(),
      endTime: _endDate!.toUtc().toIso8601String(),
      categoryId: _selectedCategory?.id,
    );

    setState(() => _isSaving = false);

    if (response == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create challenge. Please try again.')),
        );
      }
      return;
    }

    final success = response['success'] == true;
    final message = response['message'] as String? ?? 'Challenge created successfully.';
    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error']?.toString() ?? message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a New Challenge'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Challenge Title'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Category>(
                initialValue: _selectedCategory,
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        ))
                    .toList(),
                onChanged: (category) => setState(() => _selectedCategory = category),
                decoration: const InputDecoration(labelText: 'Category'),
                hint: const Text('Choose category'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await _pickDateTime(_startDate ?? DateTime.now().add(const Duration(minutes: 15)));
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                      child: Text(_startDate == null ? 'Select start time' : 'Start: ${_startDate!.toLocal()}' ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await _pickDateTime(_endDate ?? DateTime.now().add(const Duration(hours: 1, minutes: 15)));
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                      child: Text(_endDate == null ? 'Select end time' : 'End: ${_endDate!.toLocal()}' ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _questionsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Questions'),
                      validator: (val) => (val == null || int.tryParse(val.trim()) == null) ? 'Enter a number' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Time (minutes)'),
                      validator: (val) => (val == null || int.tryParse(val.trim()) == null) ? 'Enter minutes' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _thresholdType,
                onChanged: (val) {
                  if (val != null) setState(() => _thresholdType = val);
                },
                items: const [
                  DropdownMenuItem(value: 'TIME', child: Text('Time-based capacity')),
                  DropdownMenuItem(value: 'LEVEL', child: Text('Candidate level threshold')),
                ],
                decoration: const InputDecoration(labelText: 'Recruitment Filter'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thresholdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _thresholdType == 'TIME' ? 'Max participants' : 'Minimum level',
                ),
                validator: (val) => (val == null || int.tryParse(val.trim()) == null) ? 'Enter a number' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Challenge'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
