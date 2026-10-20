/// Converts a Fahrenheit value to Celsius.
double toC(num f) => (f - 32) * 5 / 9;

/// Formats a Fahrenheit value as Celsius, e.g. "23°C".
String formatTemp(num f) => '${toC(f).toStringAsFixed(0)}°C';