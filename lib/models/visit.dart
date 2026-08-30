class Visit {
  int? id;
  int counter;
  DateTime startTime;
  DateTime? endTime;
  int sessionCost;
  bool isInvalid;

  Visit({
    this.id,
    required this.counter,
    required this.startTime,
    this.endTime,
    required this.sessionCost,
    this.isInvalid = false,
  });
}
