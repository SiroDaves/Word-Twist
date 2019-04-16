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
          fontFamily: 'Quicksand',
          colorScheme: ColorScheme.dark().copyWith(secondary: Colors.pinkAccent),
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
  TwistGame twist = new TwistGame(new WordsDataSource());
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
                    Points(
                      // oldVal: twist.oldGameScore,
                      currentVal: twist.gameScore,
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
                          .map((w) => AnimatedWordBox(
                                count: w.length,
                                word: w,
                                found: twist.foundWords.contains(w),
                              ))
                          .toList(),
                    ))),
            WordHolder(
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
            ),
            Padding(
              padding: EdgeInsets.only(top: 32),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: Iterable.generate(
                  twist.length,
                  (n) => Padding(
                      padding: EdgeInsets.all(2),
                      child: MaterialButton(
                          color: theme.colorScheme.secondary,
                          minWidth: (MediaQuery.of(context).size.width - 64) / 6,
                          height: 46,
                          onPressed: () {
                            if (twist.isSelected(n)) return;
                            setState(() {
                              twist.toggleSelect(n);
                            });
                          },
                          child: AnimatedDefaultTextStyle(
                              // opacity: twist.isSelected(n) ? 0 : 1,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutSine,
                              style: twist.isSelected(n) ? const TextStyle(fontSize: 0) : const TextStyle(fontSize: 36),
                              child: Text(
                                twist[n],
                                // style: TextStyle(fontSize: 36),
                              ))))).toList(),
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
}

class AnimatedWordBox extends StatefulWidget {
  final int count;
  final String word;
  final bool found;

  const AnimatedWordBox({Key key, this.count, this.word, this.found}) : super(key: key);
  @override
  _AnimatedWordBoxState createState() => _AnimatedWordBoxState();
}

class _AnimatedWordBoxState extends State<AnimatedWordBox> with SingleTickerProviderStateMixin {
  AnimationController animationController;
  List<Animation<double>> animations;
  final BorderSide side = const BorderSide(color: Colors.white70, width: 0.3, style: BorderStyle.solid);

  @override
  void initState() {
    animationController = new AnimationController(duration: Duration(milliseconds: 125 * widget.count), vsync: this);
    animations = Iterable.generate(widget.count)
        .map((n) => Tween<double>(begin: 1.5, end: 1).animate(CurvedAnimation(
            parent: animationController,
            curve: Interval(n / widget.count, (n + 1) / widget.count, curve: Curves.easeInCubic))))
        .toList();
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.found) {
      animationController.forward();
    }
    return AnimatedBuilder(
            animation: animationController,
            builder: (BuildContext context, Widget child) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: Iterable.generate(widget.count, (n) {
                  return Transform.scale(
                      scale: widget.found ? animations[n].value : 1,
                      child: Container(
                          decoration: BoxDecoration(
                              border: (n < widget.count - 1)
                                  ? Border(top: side, bottom: side, left: side)
                                  : Border(
                                      top: side,
                                      bottom: side,
                                      left: side,
                                      right: side,
                                    )),
                          child: Opacity(
                              opacity: widget.found ? 2 - animations[n].value : 1,
                              child: SizedBox.fromSize(
                                  size: Size(20, 20),
                                  child: Center(
                                      child: Text(
                                    animations[n].value >= 1.5 ? '' : widget.word[n],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14),
                                  ))))));
                }).toList(),
              );
            },
          );
  }
}

class GameOverOverlay extends StatelessWidget {
  GameOverOverlay({Key key, this.controller, this.screenSize})
      : _widthTween = Tween<double>(begin: 0, end: screenSize.width)
            .animate(CurvedAnimation(parent: controller, curve: Interval(0, .5, curve: Curves.easeIn))),
        _heightTween = Tween<double>(begin: 0, end: screenSize.height)
            .animate(CurvedAnimation(parent: controller, curve: Interval(0, .5, curve: Curves.easeOut))),
        _opacityTween = Tween<double>(begin: 0, end: 0.8)
            .animate(CurvedAnimation(parent: controller, curve: Interval(0, .7, curve: Curves.easeIn))),
        _fontSizeTween = Tween<double>(begin: 0, end: 46)
            .animate(CurvedAnimation(parent: controller, curve: Interval(0.4, 1, curve: Curves.bounceOut))),
        super(key: key);

  final Animation<double> _opacityTween;
  final Animation<double> _fontSizeTween;
  final Animation<double> _widthTween;
  final Animation<double> _heightTween;
  final Animation<double> controller;
  final Size screenSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
        animation: controller,
        builder: (_, w) => Container(
                child: SizedBox.expand(
                    child: Center(
                        child: Opacity(
              opacity: _opacityTween.value,
              child: Container(
                  width: _widthTween.value,
                  height: _heightTween.value,
                  decoration: BoxDecoration(color: Colors.black, shape: BoxShape.rectangle),
                  child: Center(
                      child: Text(
                    'Game Over',
                    style: theme.textTheme.display1.copyWith(
                      color: Colors.white,
                      fontSize: _fontSizeTween.value,
                    ),
                  ))),
            )))));
  }
}

class Points extends StatefulWidget {
  final String oldVal;
  final String currentVal;

  Points({Key key, this.oldVal, this.currentVal}) : super(key: key);

  @override
  _PointsState createState() => _PointsState();
}

class _PointsState extends State<Points> with SingleTickerProviderStateMixin {
  AnimationController animationController;
  Animation<double> zoomAnimation;
  String score = '';
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (c, w) {
        return Transform.scale(
          scale: zoomAnimation.value,
          child: Text(
            score,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.display1,
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(Points oldWidget) {
    if (oldWidget.currentVal != widget.currentVal) {
      animationController
        ..value = 0
        ..forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    score = widget.currentVal;
    animationController = new AnimationController(duration: const Duration(milliseconds: 500), vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          animationController.reverse();
          setState(() {
            score = widget.currentVal;
          });
        }
      });
    zoomAnimation = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: animationController, curve: Interval(0, 1, curve: Curves.bounceIn)));
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}

class WordHolder extends StatefulWidget {
  final Function onTap;
  final List<String> builtWord;
  final int points;

  const WordHolder({Key key, this.onTap, this.points, this.builtWord}) : super(key: key);

  @override
  _WordHolderState createState() => _WordHolderState();
}

class _WordHolderState extends State<WordHolder> with SingleTickerProviderStateMixin {
  AnimationController animationController;
  Animation<Color> colorAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animationController,
        builder: (c, v) => GestureDetector(
            onTap: widget.onTap,
            child: Container(
                decoration: BoxDecoration(
                    color: colorAnimation.value,
                    border: Border.all(color: Colors.white, width: 0.5),
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: Iterable.generate(widget.builtWord.length).map((n) {
                    return Container(
                        child: MaterialButton(
                            minWidth: (MediaQuery.of(context).size.width - 64) / 6,
                            onPressed: null,
                            child: AnimatedDefaultTextStyle(
                              child: Text(
                                widget.builtWord[n],
                              ),
                              duration: Duration(milliseconds: 250),
                              curve: Curves.easeInSine,
                              style: widget.builtWord[n] == kSpace
                                  ? TextStyle(fontSize: 0).copyWith(color: Colors.white)
                                  : TextStyle(fontSize: 32).copyWith(color: Colors.white),
                            )));
                  }).toList(),
                ))));
  }

  @override
  void didUpdateWidget(WordHolder oldWidget) {
    if (oldWidget.points < widget.points) {
      animationController
        ..value = 0
        ..forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    animationController = new AnimationController(duration: const Duration(milliseconds: 300), vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          animationController.reverse();
        }
      });
    colorAnimation = new ColorTween(begin: Colors.black.withAlpha(0), end: Colors.grey).animate(animationController);
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}
