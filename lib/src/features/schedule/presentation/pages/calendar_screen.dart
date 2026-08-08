import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../domain/entities/schedule_entity.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  List<ScheduleEntity> _scheduledPosts = const <ScheduleEntity>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScheduledPosts();
  }

  Future<void> _loadScheduledPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref
        .read(scheduleRepositoryProvider)
        .getCalendarEntries();

    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _scheduledPosts = result.data ?? const <ScheduleEntity>[];
      } else {
        _error = result.message ?? l10n.calendarFailedToLoad;
      }
    });
  }

  List<ScheduleEntity> get _selectedDayPosts {
    return _scheduledPosts
        .where((entry) {
          final schedule = entry.scheduledAt;
          return schedule.year == _selectedDate.year &&
              schedule.month == _selectedDate.month &&
              schedule.day == _selectedDate.day;
        })
        .toList(growable: false);
  }

  int _eventsForDay(DateTime day) {
    return _scheduledPosts.where((entry) {
      final schedule = entry.scheduledAt;
      return schedule.year == day.year &&
          schedule.month == day.month &&
          schedule.day == day.day;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final dayPosts = _selectedDayPosts;
    final l10n = AppLocalizations.of(context)!;
    final selectedDayIsToday = DateUtils.isSameDay(
      _selectedDate,
      DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarAppBarTitle)),
      body: AdaptiveContentWidth(
        child: RefreshIndicator(
          onRefresh: _loadScheduledPosts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: <Widget>[
              Text(
                l10n.calendarSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
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
              const SizedBox(height: AppSpacing.md),
              AnimatedContainer(
                duration: AppDuration.slow,
                curve: AppCurves.standard,
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selectedDayIsToday
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l10n.calendarMonthLabel(
                              '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: AppDuration.normal,
                          switchInCurve: AppCurves.standard,
                          switchOutCurve: AppCurves.standard,
                          child: Text(
                            l10n.calendarEventsLabel(
                              _eventsForDay(_selectedDate),
                            ),
                            key: ValueKey<DateTime>(_selectedDate),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedSwitcher(
                duration: AppDuration.normal,
                switchInCurve: AppCurves.standard,
                switchOutCurve: AppCurves.standard,
                child: Text(
                  l10n.calendarScheduledForDate(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                  key: ValueKey<DateTime>(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(_error!),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: _loadScheduledPosts,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
                )
              else if (dayPosts.isEmpty)
                AppEmptyState(
                  message: l10n.calendarNoScheduledPosts,
                  icon: Icons.event_busy_outlined,
                )
              else
                ...dayPosts.map(
                  (entry) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: Text(
                        entry.title.isEmpty ? l10n.postUntitled : entry.title,
                      ),
                      subtitle: Text(
                        '${_statusLabel(entry.status, l10n)}\n${_formatSchedule(entry.scheduledAt, l10n)}',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(String status, AppLocalizations l10n) {
    return l10n.calendarStatusLabel(
      status.isEmpty ? l10n.calendarDefaultStatus : status,
    );
  }

  static String _formatSchedule(DateTime value, AppLocalizations l10n) {
    final local = value.toLocal();
    return l10n.calendarScheduleLabel(
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}',
    );
  }
}
