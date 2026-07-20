import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../posts/domain/entities/post_entity.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  List<PostEntity> _scheduledPosts = const <PostEntity>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledPosts();
  }

  Future<void> _loadScheduledPosts() async {
    setState(() {
      _loading = true;
    });

    final result = await ref.read(postRepositoryProvider).getPosts();
    final posts = result.data ?? const <PostEntity>[];
    final scheduled = posts.where((post) => post.scheduledAt != null).toList(growable: false);

    if (!mounted) {
      return;
    }

    setState(() {
      _scheduledPosts = scheduled;
      _loading = false;
    });
  }

  List<PostEntity> get _selectedDayPosts {
    return _scheduledPosts.where((post) {
      final schedule = post.scheduledAt;
      if (schedule == null) {
        return false;
      }
      return schedule.year == _selectedDate.year &&
          schedule.month == _selectedDate.month &&
          schedule.day == _selectedDate.day;
    }).toList(growable: false);
  }

  int _eventsForDay(DateTime day) {
    return _scheduledPosts.where((post) {
      final schedule = post.scheduledAt;
      if (schedule == null) {
        return false;
      }
      return schedule.year == day.year &&
          schedule.month == day.month &&
          schedule.day == day.day;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final dayPosts = _selectedDayPosts;

    return Scaffold(
      appBar: AppBar(title: const Text('Publishing Calendar')),
      body: RefreshIndicator(
        onRefresh: _loadScheduledPosts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Text(
              'Track scheduled posts by date and keep publishing cadence on time.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: DateTime(DateTime.now().year - 2),
                  lastDate: DateTime(DateTime.now().year + 2),
                  currentDate: DateTime.now(),
                  onDisplayedMonthChanged: (month) {
                    setState(() {
                      _focusedMonth = DateTime(month.year, month.month);
                    });
                  },
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Month: ${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}',
                      ),
                    ),
                    Text('Events: ${_eventsForDay(_selectedDate)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Scheduled for ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (dayPosts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No scheduled posts on this date.'),
                ),
              )
            else
              ...dayPosts.map(
                (post) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(post.title.isEmpty ? 'Untitled post' : post.title),
                    subtitle: Text(
                      '${post.body}\n${_formatSchedule(post.scheduledAt!)}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatSchedule(DateTime value) {
    final local = value.toLocal();
    return 'Schedule: ${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
