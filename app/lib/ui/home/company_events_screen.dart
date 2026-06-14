import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../models/question.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_service.dart';
import '../../services/question_service.dart';
import 'create_event_screen.dart';

class CompanyEventsScreen extends StatefulWidget {
  const CompanyEventsScreen({super.key});

  @override
  State<CompanyEventsScreen> createState() => _CompanyEventsScreenState();
}

class _CompanyEventsScreenState extends State<CompanyEventsScreen> {
  bool _isLoading = true;
  List<Event> _events = [];
  final List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final events = await EventService.fetchRecruiterEvents();
    if (mounted) {
      setState(() {
        _events = events;
        _isLoading = false;
      });
    }
  }

  void _navigateToCreate() async {
    final didCreate = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateEventScreen()),
    );
    if (didCreate == true) {
      _loadEvents();
    }
  }

  Widget _buildEventCard(Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(event.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Chip(
                    label: Text(event.category.isNotEmpty ? event.category : 'General'),
                    backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
                    labelStyle: const TextStyle(color: AppTheme.secondary, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(event.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMetric('Questions', '${event.totalQuestions}'),
                  _buildMetric('Duration', '${(event.timeLimitSeconds / 60).round()}m'),
                  _buildMetric('Status', event.isLive ? 'Live' : event.isUpcoming ? 'Upcoming' : 'Closed'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Recruiter Events'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
            onPressed: _navigateToCreate,
            tooltip: 'Post a New Challenge',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _events.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 140),
                      Center(
                        child: Text(
                          'No recruiter events found yet. Tap + to post your first challenge.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.4),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome back, ${auth.currentUser?.organization ?? auth.currentUser?.username ?? 'Recruiter'}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('${_events.length} Posted Challenges', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                      ..._events.map(_buildEventCard),
                    ],
                  ),
      ),
    );
  }
}
