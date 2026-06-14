import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../services/candidate_service.dart';

class CandidateDetailScreen extends StatefulWidget {
  final String username;

  const CandidateDetailScreen({required this.username, super.key});

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  bool _isLoading = true;
  CandidateProfile? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final profile = await CandidateService.fetchCandidateDetail(widget.username);
    if (!mounted) return;

    setState(() {
      _profile = profile;
      _isLoading = false;
      _error = profile == null ? 'Unable to load candidate details.' : null;
    });
  }

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.username),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: _isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 220), Center(child: CircularProgressIndicator(color: AppTheme.primary))],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 180),
                      Center(child: Text(_error!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15))),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
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
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [AppTheme.primary, AppTheme.secondary],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _profile!.user.username.isNotEmpty ? _profile!.user.username[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _profile!.user.username,
                                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _profile!.user.currentStatus ?? 'Candidate',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _profile!.user.interestedField ?? 'No specialization provided',
                                        style: const TextStyle(color: AppTheme.accent, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _buildChip('Level ${_profile!.user.level}'),
                                _buildChip('${_profile!.user.exp} XP'),
                                _buildChip('${_profile!.user.coins} Coins'),
                                _buildChip('${_profile!.user.lives} Lives'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: _labelValue('Total Attempts', '${_profile!.totalAttempts}')),
                          Expanded(child: _labelValue('Average Categories', '${_profile!.categoryStats.length}')),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if ((_profile!.recentAttempts).isNotEmpty) ...[
                        const Text('Recent Attempts', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ..._profile!.recentAttempts.map((attempt) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.surfaceLight),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(attempt.category, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text('Completed ${attempt.completedAt ?? 'recently'}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text('${attempt.score} pts', style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }),
                      ],
                      if ((_profile!.categoryStats).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Category Performance', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ..._profile!.categoryStats.map((stat) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.surfaceLight),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(stat.category, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text('${stat.count} attempts', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text('${stat.avgScore.toStringAsFixed(1)} avg', style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }),
                      ]
                    ],
                  ),
      ),
    );
  }
}
