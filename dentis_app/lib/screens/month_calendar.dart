import 'package:flutter/material.dart';

class MonthCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Color accentColor;

  const MonthCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.accentColor,
  });

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime visibleMonth;

  static const Color card = Color(0xff14282D);
  static const Color muted = Color(0xff7D8B90);

  @override
  void initState() {
    super.initState();
    visibleMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  void previousMonth() {
    setState(() {
      visibleMonth = DateTime(visibleMonth.year, visibleMonth.month - 1);
    });
  }

  void nextMonth() {
    setState(() {
      visibleMonth = DateTime(visibleMonth.year, visibleMonth.month + 1);
    });
  }

  List<DateTime> get calendarDays {
    final first = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final offset = first.weekday - 1;
    final start = first.subtract(Duration(days: offset));

    return List.generate(42, (index) {
      return start.add(Duration(days: index));
    });
  }

  bool sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String monthName(int month) {
    const months = [
      "enero",
      "febrero",
      "marzo",
      "abril",
      "mayo",
      "junio",
      "julio",
      "agosto",
      "septiembre",
      "octubre",
      "noviembre",
      "diciembre",
    ];
    return months[month - 1];
  }

  String weekdayName(int weekday) {
    const days = [
      "lunes",
      "martes",
      "miércoles",
      "jueves",
      "viernes",
      "sábado",
      "domingo",
    ];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final titleDate = widget.selectedDate;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "${weekdayName(titleDate.weekday)}, ${titleDate.day} de ${monthName(titleDate.month)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: previousMonth,
                  icon: const Icon(Icons.keyboard_arrow_up),
                  color: Colors.white70,
                ),
                IconButton(
                  onPressed: nextMonth,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  color: Colors.white70,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x1FFFFFFF)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${monthName(visibleMonth.month)} de ${visibleMonth.year}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                _weekHeader(),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: calendarDays.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final day = calendarDays[index];
                    final selected = sameDay(day, widget.selectedDate);
                    final inMonth = day.month == visibleMonth.month;

                    return InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => widget.onDateSelected(day),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? widget.accentColor : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "${day.day}",
                          style: TextStyle(
                            color: selected
                                ? Colors.black87
                                : inMonth
                                    ? Colors.white
                                    : muted,
                            fontSize: 16,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekHeader() {
    const labels = ["LU", "MA", "MI", "JU", "VI", "SA", "DO"];

    return Row(
      children: labels.map((label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
