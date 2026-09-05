/// اسم اليوم بالعربي من DateTime (Mon=1 .. Sun=7).
String arabicWeekday(DateTime d) {
  const days = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  return days[(d.weekday - 1) % 7];
}

/// الوقت بصيغة 12 ساعة + م/ص، مثال "9:00م".
String arabicTime(DateTime d) {
  final pm = d.hour >= 12;
  var h = d.hour % 12;
  if (h == 0) h = 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m${pm ? 'م' : 'ص'}';
}
