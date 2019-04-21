import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:word_twist/data/user_prefs.dart';
import 'package:word_twist/game/twist.dart';
import 'package:word_twist/data/word_repo.dart';
import 'package:word_twist/game/user_prefs_impl.dart';
import 'package:word_twist/ui/game_over_overlay.dart';
import 'package:word_twist/ui/points.dart';
import 'package:word_twist/ui/word_box.dart';
import 'package:word_twist/ui/word_holder.dart';

void main() async {
  WordsDataSource dataSource = new WordsDataSource();
  if (!await dataSource.isDbLoaded()) {
    await dataSource.loadDatabase();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      title: 'Word Twist',
      theme: ThemeData(
          fontFamily: 'Quicksand',
          colorScheme: ColorScheme.dark().copyWith(secondary: Colors.blueAccent),
          brightness: Brightness.dark,
          primarySwatch: Colors.deepPurple),
      home: MyHomePage(title: 'Word Twist'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver, TickerProviderStateMixin {
  final TwistGame twist = new TwistGame(new WordsDataSource());
  final UserPrefs _userPrefs = new UserPrefsImpl();

  bool _isLoading = false;
  GameTimer _timer;
  AnimationController _animationController;
  Animation<double> _animation;
  AnimationController _shakeController;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _shakeController = new AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..addListener(() {
        setState(() {});
      });
    _animationController = new AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOutSine);
    _timer = new GameTimer(_onTimeExpired, _onTimeTick);
    _createNewGame();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.dispose();
    _shakeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _createNewGame() {
    setState(() {
      _isLoading = true;
    });

    twist.createNewGame().then((v) {
      setState(() {
        _isLoading = false;
      });
      _timer.restartTimer();
    });
  }

  void _onTimeExpired() {
    setState(() {
      _timer.isTimeExpired;
    });
    if (_animationController.status == AnimationStatus.completed) _animationController.reset();
    _animationController.forward();
  }

  void _onTimeTick() {
    setState(() {
      _timer.gameTime;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((_timer.isPaused && state == AppLifecycleState.resumed) ||
        (!_timer.isPaused && state != AppLifecycleState.resumed)) {
      _timer.togglePause();
    }
  }

  Vector3 _getTranslation() {
    double progress = _shakeController.value;
    double offset = sin(progress * pi * 7) * 10;
    return Vector3(offset, offset / 10, 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> stackChildren = [
      Padding(
        padding: EdgeInsets.only(bottom: 16, left: 16, right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: Padding(
                    padding: EdgeInsets.only(bottom: 24, top: 24),
                    child: GridView.count(
                      childAspectRatio: 5,
                      padding: EdgeInsets.all(0),
                      crossAxisCount: 3,
                      children: twist.possibleWords
                          .map((w) => AnimatedWordBox(
                                count: w.length,
                                word: w,
                                found: twist.foundWords.contains(w),
                              ))
                          .toList(),
                    ))),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: WordHolder(
                  onTap: () {
                    int i = twist.builtWord.lastIndexWhere((s) => s != kSpace);
                    if (i >= 0) {
                      setState(() {
                        twist.toggleSelect(twist.sourceLetters.indexOf(twist.builtWord[i]));
                      });
                    }
                  },
                  builtWord: twist.builtWord,
                  points: twist.gameScoreInt,
                )),
            Padding(
              padding: EdgeInsets.only(top: 24),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: Iterable.generate(
                  twist.length,
                  (n) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                          onTap: () {
                            if (twist.isSelected(n)) return;
                            setState(() {
                              twist.toggleSelect(n);
                            });
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(width: .4, color: Colors.white)),
                              height: 46,
                              width: 42,
                              child: Center(
                                  child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOutSine,
                                      style: twist.isSelected(n)
                                          ? const TextStyle(fontSize: 0)
                                          : const TextStyle(fontSize: 32),
                                      child: Text(
                                        twist[n],
                                        // style: TextStyle(fontSize: 36),
                                      ))))))).toList(),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('Twist'),
                  onPressed: () {
                    setState(() {
                      twist.twistWord();
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                RaisedButton(
                  child: Text('Clear'),
                  onPressed: () {
                    setState(() {
                      twist.resetSelection();
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                RaisedButton(
                  child: Text('Enter'),
                  onPressed: () {
                    final w = twist.builtWord.join().toLowerCase().trim();
                    if (twist.possibleWords.contains(w)) {
                      setState(() {
                        twist.foundWords.add(w);
                        twist.resetSelection();
                        twist.gameScore;
                      });
                    } else {
                      _shakeController.reset();
                      _shakeController.forward();
                    }
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                )
              ],
            )
          ],
        ),
      )
    ];

    if (_timer.isTimeExpired) {
      stackChildren.add(GameOverOverlay(
        controller: _animation,
        screenSize: MediaQuery.of(context).size,
      ));
    }

    return Scaffold(
        appBar: AppBar(
          title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              _timer.gameTime,
              textAlign: TextAlign.center,
              style: theme.textTheme.display1,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
            ),
            IconButton(
              icon: Icon(Icons.plus_one),
              onPressed: _timer.seconds > 0
                  ? () async {
                      if (await _confirmCoinSpend()) {
                        _timer.addTime(60);
                        setState(() {});
                      }
                    }
                  : null,
            ),
          ]),
          centerTitle: true,
          actions: <Widget>[
            Center(
                child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Points(
                      currentVal: twist.gameScore,
                    )))
          ],
        ),
        drawer: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            children: <Widget>[
              RaisedButton(
                child: Text('New Game'),
                onPressed: () {
                  _createNewGame();
                  Navigator.pop(context);
                },
              ),
              RaisedButton(
                child: Text('Solve'),
                onPressed: () {
                  setState(() {
                    twist.solveAll();
                    Navigator.pop(context);
                  });
                  _timer.stop();
                  _onTimeExpired();
                },
              )
            ],
          ),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Transform(
                transform: Matrix4.translation(_getTranslation()),
                child: Stack(
                  children: stackChildren,
                )));
  }

  Future<bool> _confirmCoinSpend() {
    if (_userPrefs.getBool(_kDontAskAgianCoins) ?? false) {
      return Future.value(true);
    } else {      
      final completer = new Completer<bool>();
      showDialog(
        context: context,
        builder: (c) => SpendCoinsAlertDialog(completer: completer,),
      );
      return completer.future;
    }
  }
}

const _kDontAskAgianCoins = 'DontAskAgainCoins';

class SpendCoinsAlertDialog extends StatefulWidget {
  final Completer<bool> completer;

  const SpendCoinsAlertDialog({Key key, this.completer}) : super(key: key);

  @override
  _SpendCoinsAlertDialogState createState() => _SpendCoinsAlertDialogState();
}

class _SpendCoinsAlertDialogState extends State<SpendCoinsAlertDialog> {
  bool checked = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Extend Time"),
      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        const Text("Do you want to spend 5 coins to extend game time by 1 minute?"),
        Row(
          children: <Widget>[
            Checkbox(
              value: checked,
              onChanged: (v) {
                setState(() {
                  checked = v;
                });
              },
            ),
            const Text("Don't ask again")
          ],
        )
      ]),
      actions: <Widget>[
        FlatButton(
          child: Text("No"),
          onPressed: () {
            Navigator.of(context).pop();
            widget.completer.complete(false);
          },
        ),
        FlatButton(
          child: Text("Yes"),
          onPressed: () {
            Navigator.of(context).pop();
            widget.completer.complete(true);
          },
        ),
      ],
    );
  }
}
