import 'package:flutter/material.dart';
import 'package:flutter_ppb_assignment_1/components/score_card.dart';
import 'package:flutter_ppb_assignment_1/model/score.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const TapTimeApp());
}

class TapTimeApp extends StatelessWidget {
  const TapTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TapTimeGame());
  }
}

class TapTimeGame extends StatefulWidget {
  const TapTimeGame({super.key});

  @override
  TapTimeGameState createState() => TapTimeGameState();
}

class TapTimeGameState extends State<TapTimeGame> {
  String playerName = "Player 1";
  String message = "Let's Get Started!";
  Color bgColor = Colors.teal;

  Timer? timer;
  int startTime = 0;
  int reactionTime = 0;

  bool gameActive = false;
  bool waitingForGreen = false;

  List<Score> scores = [];
  int? bestTime;

  @override
  void initState() {
    super.initState();
    loadScores();
  }

  Future<void> loadScores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedScores = prefs.getStringList('scores');
    if (storedScores != null) {
      setState(() {
        scores =
            storedScores.map((e) => Score.fromJson(jsonDecode(e))).toList();
        bestTime =
            scores.isEmpty
                ? null
                : scores.map((s) => s.reactionTime).reduce(min);
      });
    }
  }

  Future<void> saveScores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'scores',
      scores.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  void startGame() {
    setState(() {
      message = "Wait for Green...";
      bgColor = Colors.red;
      gameActive = true;
      waitingForGreen = true;
      reactionTime = 0;
    });

    int delay = Random().nextInt(3000) + 2000; // 2 - 5 seconds
    timer = Timer(Duration(milliseconds: delay), () {
      setState(() {
        bgColor = Colors.green;
        message = "IT'S TAP TIME!";
        startTime = DateTime.now().millisecondsSinceEpoch;
        waitingForGreen = false;
      });
    });
  }

  void handleTap() {
    if (!gameActive) return;
    int endTime = DateTime.now().millisecondsSinceEpoch;

    if (waitingForGreen) {
      setState(() {
        message = "Too Soon! Try Again";
        bgColor = Colors.teal;
        gameActive = false;
      });
      timer?.cancel();
    } else {
      setState(() {
        reactionTime = endTime - startTime;
        DateTime now = DateTime.now().toLocal();
        String attemptTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
        scores.add(
          Score(
            name: playerName,
            reactionTime: reactionTime,
            attemptTime: attemptTime,
          ),
        );

        var isNewHighScore = (bestTime == null || reactionTime < bestTime!);
        bestTime =
            bestTime == null ? reactionTime : min(bestTime!, reactionTime);

        if (isNewHighScore) {
          message = "New High Score!\nYou've tapped in ${reactionTime}ms.";
        } else {
          message = "Nice Try!\nYou've tapped in ${reactionTime}ms.";
        }

        bgColor = Colors.teal;
        gameActive = false;
      });
      saveScores();
    }
  }

  void _editScore(Score score, StateSetter setSheetState) {
    TextEditingController nameController = TextEditingController(
      text: score.name,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Player Name"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Player Name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  score.name = nameController.text;
                });
                saveScores();
                setSheetState(() {});
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _editName() {
    TextEditingController nameController = TextEditingController(
      text: playerName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Player Name"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Player Name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  playerName = nameController.text;
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteScore(Score score) {
    setState(() {
      scores.remove(score);
      bestTime =
          scores.isEmpty ? null : scores.map((s) => s.reactionTime).reduce(min);
    });
    saveScores();
  }

  void _showScoreHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children:
                    scores.map((score) {
                      return ScoreCard(
                        score: score,
                        delete: () {
                          _deleteScore(score);
                          setSheetState(() {});
                        },
                        edit: () {
                          _editScore(score, setSheetState);
                        },
                      );
                    }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "TapTime!",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.cyan,
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: handleTap,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                color: bgColor,
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (bestTime != null && !gameActive)
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          "Best Time: ${bestTime}ms",
                          style: TextStyle(fontSize: 20, color: Colors.amber),
                        ),
                      ),
                    SizedBox(height: 20),
                    if (!gameActive)
                      ElevatedButton(
                        onPressed: gameActive ? null : startGame,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.orange,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            "Start Game",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 4),
                    if (!gameActive)
                      ElevatedButton(
                        onPressed: () {
                          _showScoreHistory();
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.orange,
                        ),
                        child: Text(
                          "View History",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    SizedBox(height: 40),
                    if (!gameActive)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.cyan,
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // Rounded corners
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 14),
                              child: Text(
                                playerName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit),
                              iconSize: 12,
                              onPressed: _editName,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
