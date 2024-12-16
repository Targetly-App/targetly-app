final taskRepeats = ["once", "hourly", "daily", "weekly", "monthly", "yearly"];
final daysOfWeek = ["M", "T", "W", "T", "F", "S", "S"];
// 1-99
final impactLevels = [
  "Nice to Have",
  "Slightly Important",
  "Somewhat Important",
  "Moderately Important",
  "Important",
  "Quite Important",
  "Very Important",
  "Highly Important",
  "Essential",
  "Critical",
];
final effortLevels = [
  "Tiny",
  "Very Small",
  "Small",
  "Light",
  "Medium",
  "Above Medium",
  "Large",
  "Very Large",
  "Huge",
  "Massive",
];
final taskIterations = List.generate(99, (index) => (index + 1).toString());
final taskDurations = [
  "5m",
  "10m",
  "15m",
  "30m",
  "1h",
  "1h 30m",
  "2h",
  "2h 30m",
  "3h",
  "3h 30m",
  "4h",
  "4h 30m",
  "5h",
  "5h 30m",
  "6h",
  "6h 30m",
  "7h",
  "7h 30m",
  "8h",
];
