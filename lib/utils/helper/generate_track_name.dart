String generateUniqueTrackName() {
  final now = DateTime.now();
  final timestamp =
      "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_"
      "${now.hour.toString().padLeft(2, '0')}"
      "${now.minute.toString().padLeft(2, '0')}"
      "${now.second.toString().padLeft(2, '0')}";

  final randomId = (1000 + (DateTime.now().microsecond % 9000)).toString();

  return "VisionScore_${timestamp}_$randomId";
}