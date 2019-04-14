import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:word_twist/data/twist.dart';
import 'package:word_twist/data/word_repo.dart';

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
          colorScheme:
          ColorScheme.dark().copyWith(secondary: Colors.pinkAccent),
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

class _MyHomePageState extends State<MyHomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  TwistGame twist = new TwistGame(new WordsDataSource());
  bool _isLoading = false;
  GameTimer _timer;
  AnimationController _animationController;
  Animation<double> _animation;
  AnimationController _shakeController;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _shakeController = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750))
      ..addListener(() {
        setState(() {});
      });
    _animationController = new AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _animation = CurvedAnimation(
        parent: _animationController, curve: Curves.easeInOutSine);
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
    if (_animationController.status == AnimationStatus.completed)
      _animationController.reset();
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

  Vector3 getTranslation() {
    double progress = _shakeController.value;
    double offset = sin(progress * pi * 5) * 10;
    return Vector3(offset, offset / 8, 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> stackChildren = [
      Padding(
        padding: EdgeInsets.only(bottom: 32, left: 16, right: 16, top: 42),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      _timer.gameTime,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.display1,
                    ),
                    Text(
                      twist.gameScore,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.display1,
                    ),
                  ],
                )),
            Expanded(
                child: Padding(
                    padding: EdgeInsets.only(bottom: 24, top: 24),
                    child: GridView.count(
                      childAspectRatio: 5,
                      padding: EdgeInsets.all(0),
                      crossAxisCount: 3,
                      children: twist.possibleWords
                          .map((w) =>
                          WordBox(
                            count: w.length,
                            word: w,
                            found: twist.foundWords.contains(w),
                          ))
                          .toList(),
                    ))),
            GestureDetector(
                onTap: () {
                  int i = twist.builtWord.lastIndexWhere((s) => s != kSpace);
                  if (i >= 0) {
                    setState(() {
                      twist.toggleSelect(
                          twist.sourceLetters.indexOf(twist.builtWord[i]));
                    });
                  }
                },
                child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 0.5)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                      Iterable.generate(twist.builtWord.length).map((n) {
                        return Container(
//                      decoration: BoxDecoration(
//                          border: Border.all(color: Colors.white, width: 1)),
                            child: MaterialButton(
                              minWidth:
                              (MediaQuery
                                  .of(context)
                                  .size
                                  .width - 64) / 6,
//                onPressed: () {},
                              disabledElevation: 4,
                              child: Text(
                                twist.builtWord[n],
                                style: TextStyle(fontSize: 30)
                                    .copyWith(color: Colors.white),
                              ),
                            ));
                      }).toList(),
                    ))),
            Padding(
              padding: EdgeInsets.only(top: 32),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: Iterable.generate(
                  twist.length,
                      (n) =>
                      Padding(
                          padding: EdgeInsets.all(2),
                          child: MaterialButton(
                              color: theme.colorScheme.secondary,
                              minWidth:
                              (MediaQuery
                                  .of(context)
                                  .size
                                  .width - 64) / 6,
                              onPressed: () {
                                if (twist.isSelected(n)) return;
                                setState(() {
                                  twist.toggleSelect(n);
                                });
                              },
                              child: Text(
                                twist.isSelected(n) ? kSpace : twist[n],
                                style: TextStyle(fontSize: 36),
                              )))).toList(),
            ),
            Padding(
              padding: EdgeInsets.only(top: 32),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                RaisedButton(
                  child: Text('Clear'),
                  onPressed: () {
                    setState(() {
                      twist.resetSelection();
                    });
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                RaisedButton(
                  child: Text('Enter'),
                  onPressed: () {
                    final w = twist.builtWord.join().toLowerCase().trim();
                    if (twist.possibleWords.contains(w.toLowerCase())) {
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                )
              ],
            )
          ],
        ),
      )
    ];

    if (_timer.isTimeExpired) {
      stackChildren.add(GameOverOverlay(
        animation: _animation,
      ));
    }

    return Scaffold(
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
            transform: Matrix4.translation(getTranslation()),
            child: Stack(
              children: stackChildren,
            )));
  }
}

class WordBox extends StatelessWidget {
  final int count;
  final String word;
  final bool found;

  const WordBox({Key key, this.count, this.word, this.found = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: Iterable.generate(count, (n) {
        return Container(
            decoration: BoxDecoration(
                border: Border.all(width: 0.3, color: Colors.white70)),
            child: SizedBox.fromSize(
                size: Size(20, 20),
                child: Center(
                    child: Text(
                      found ? word[n] : '',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ))));
      }).toList(),
    );
  }
}

class GameOverOverlay extends AnimatedWidget {
  static final _opacityTween = Tween<double>(begin: 0.1, end: 1);
  static final _fontSizeTween = Tween<double>(begin: 0, end: 46);
  Tween<double> _widthTween;
  Tween<double> _heightTween;

  GameOverOverlay({Key key, Animation<double> animation})
      : super(key: key, listenable: animation) {}

  @override
  Widget build(BuildContext context) {
    _widthTween =
        Tween<double>(begin: 0, end: MediaQuery
            .of(context)
            .size
            .width);
    _heightTween =
        Tween<double>(begin: 0, end: MediaQuery
            .of(context)
            .size
            .height);
    final theme = Theme.of(context);
    final Animation<double> animation = listenable;
    return Container(
        child: SizedBox.expand(
            child: Center(
              child: Opacity(
                  opacity: _opacityTween.evaluate(animation),
                  child: Container(
                      width: _widthTween.evaluate(animation),
                      height: _heightTween.evaluate(animation),
                      decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          shape: BoxShape.rectangle),
                      child: Center(
                        child: Text(
                          'Game Over',
                          style: theme.textTheme.display1.copyWith(
                              color: Colors.white,
                              fontSize: _fontSizeTween.evaluate(animation)),
                        ),
                      ))),
            )));
  }
}
