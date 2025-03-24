class Score {
  String name;
  int reactionTime;
  String attemptTime;

  Score({
    required this.name,
    required this.reactionTime,
    required this.attemptTime,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'reactionTime': reactionTime,
    'attemptTime': attemptTime,
  };

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      name: json['name'],
      reactionTime: json['reactionTime'],
      attemptTime: json['attemptTime'],
    );
  }
}
