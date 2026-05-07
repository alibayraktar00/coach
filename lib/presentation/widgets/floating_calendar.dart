import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/glass_morphism.dart';

class FloatingCalendar extends StatefulWidget {
  const FloatingCalendar({
    super.key,
    this.onSelectedDayChanged,
    this.initialSelectedDay,
  });

  final ValueChanged<DateTime>? onSelectedDayChanged;
  final DateTime? initialSelectedDay;

  @override
  State<FloatingCalendar> createState() => _FloatingCalendarState();
}

class _FloatingCalendarState extends State<FloatingCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialSelectedDay ?? DateTime.now();
    _focusedDay = _selectedDay ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: AntigravityTheme.floatingShadow,
      ),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            widget.onSelectedDayChanged?.call(selectedDay);
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          // Custom Styling
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white70),
            rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white70),
          ),
          calendarStyle: CalendarStyle(
            defaultTextStyle: const TextStyle(color: Colors.white),
            weekendTextStyle: const TextStyle(color: AntigravityTheme.secondary),
            outsideTextStyle: const TextStyle(color: Colors.white24),
            todayDecoration: BoxDecoration(
              color: AntigravityTheme.primary.withAlpha((255 * 0.3).toInt()),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            outsideDaysVisible: true,
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Colors.white60),
            weekendStyle: TextStyle(color: AntigravityTheme.secondary),
          ),
          calendarBuilders: CalendarBuilders(
            selectedBuilder: (context, day, focusedDay) {
              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AntigravityTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
            todayBuilder: (context, day, focusedDay) {
              final isSelected = isSameDay(_selectedDay, day);
              if (isSelected) {
                return const SizedBox.shrink();
              }
              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AntigravityTheme.primary.withAlpha((255 * 0.25).toInt()),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
