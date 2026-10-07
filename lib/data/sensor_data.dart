class DailyReading {
  const DailyReading(this.day, this.tempF, this.smokePpm);
  final String day;
  final double tempF;
  final double smokePpm;
}

class SensorData {
  SensorData._();

  static const sensors = ['Kitchen Detector', 'Living Room Detector'];
  static const tempF = 72.0;
  static const smokePpm = 0.02;
  static const humidity = 44;
  static const health = 98;

  static const week = [
    DailyReading('Mon', 70, 0.02),
    DailyReading('Tue', 71, 0.02),
    DailyReading('Wed', 72, 0.03),
    DailyReading('Thu', 72, 0.02),
    DailyReading('Fri', 71, 0.02),
    DailyReading('Sat', 71, 0.01),
    DailyReading('Sun', 73, 0.02),
  ];

  static double get avgTemp =>
      week.fold(0.0, (sum, r) => sum + r.tempF) / week.length;

  static double get avgSmoke =>
      week.fold(0.0, (sum, r) => sum + r.smokePpm) / week.length;
}
