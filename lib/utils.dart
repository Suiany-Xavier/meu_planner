String _two(int n) => n.toString().padLeft(2, '0');

/// 11/11/2023
String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
