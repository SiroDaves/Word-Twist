import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:flare_flutter/flare_actor.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:word_twist/data/user_prefs.dart';
import 'package:word_twist/game/coins_store.dart';
import 'package:word_twist/game/twist.dart';
import 'package:word_twist/data/word_repo.dart';
import 'package:word_twist/game/user_prefs_impl.dart';
import 'package:word_twist/ui/coins_overlay.dart';
import 'package:word_twist/ui/drawer.dart';
import 'package:word_twist/ui/game_over_overlay.dart';
import 'package:word_twist/ui/points.dart';
import 'package:word_twist/ui/word_box.dart';
import 'package:word_twist/ui/word_holder.dart';

void main() async {
  WordsDataSource dataSource = new WordsDataSource();
  if (!await dataSource.isDbLoaded()) {
    await dataSource.loadDatabase();
  }
  await SharedPreferences.getInstance();
  await UserPrefsImpl.instance().init();
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
        primarySwatch: Colors.deepPurple,
        toggleableActiveColor: Colors.purpleAccent,
        accentColor: Colors.blueAccent,
      ),
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
  final UserPrefs _userPrefs = UserPrefsImpl.instance();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();

  bool _isLoading = false;
  bool _coinsEarned = false;

  GameTimer _gameTimer;
  CoinsStore _coinsStore;

  Animation<double> _gameOverAnimation;
  Animation<double> _timerScaleAnimation;

  AnimationController _gameOverAnimController;
  AnimationController _shakeAnimController;
  AnimationController _coinsAnimController;
  AnimationController _timerScaleController;

  @override
  void initState() {
    _coinsStore = new CoinsStore(_userPrefs);
    WidgetsBinding.instance.addObserver(this);
    _shakeAnimController = new AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..addListener(() {
        setState(() {});
      });
    _gameOverAnimController = new AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _coinsAnimController = new AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() {
            _coinsEarned = false;
          });
          _coinsAnimController.value = 0;
        }
      });
    _gameOverAnimation = CurvedAnimation(parent: _gameOverAnimController, curve: Curves.easeInOutSine);
    _timerScaleController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && !_gameTimer.isTimeExpired) {
          _timerScaleController.reverse();
        } else if (_gameTimer.isTimeExpired) {
          setState(() {
            _timerScaleController.value = 0;
          });
        }
      });
    _timerScaleAnimation = Tween<double>(begin: 1, end: 1.2).animate(_timerScaleController);
    _gameTimer = new GameTimer(_onTimeExpired, _onTimeTick);
    Future.delayed(Duration(milliseconds: 500)).then((v) => _scaffoldKey.currentState.openDrawer());
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameTimer.dispose();
    _shakeAnimController.dispose();
    _gameOverAnimController.dispose();
    _coinsAnimController.dispose();
    _timerScaleController.dispose();
    super.dispose();
  }

  Future _createNewGame(GameMode mode) async {
    setState(() {
      _isLoading = true;
    });

    await twist.createNewGame(mode);
    setState(() {
      _isLoading = false;
    });
    _coinsStore.reset();
    if (mode != GameMode.unlimited) {
      _gameTimer.restartTimer();
    }
    _timerScaleController.value = 0;
  }

  void _onTimeExpired() {
    setState(() {
      _gameTimer.isTimeExpired;
    });
    if (_gameOverAnimController.status == AnimationStatus.completed) _gameOverAnimController.reset();
    _gameOverAnimController.forward();
  }

  void _onTimeTick() {
    setState(() {
      _gameTimer.gameTime;
    });
    if (_gameTimer.seconds < 30 && _timerScaleController.status == AnimationStatus.dismissed) {
      _timerScaleController.forward();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((_gameTimer.isPaused && state == AppLifecycleState.resumed) ||
        (!_gameTimer.isPaused && state != AppLifecycleState.resumed)) {
      _gameTimer.togglePause();
    }
  }

  Vector3 _getTranslation() {
    double progress = _shakeAnimController.value;
    double offset = sin(progress * pi * 7) * 10;
    return Vector3(offset, offset / 10, 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> stackChildren = [
      FlareActor(
        'assets/Background.flr',
        alignment: Alignment.center,
        fit: BoxFit.fill,
        animation: 'rotate',
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(bottom: 24, top: 24),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  foundWords: twist.foundWords.length,
                )),
            Padding(
              padding: const EdgeInsets.only(top: 24),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: Iterable.generate(
                  twist.length,
                  (n) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Material(
                          color: Colors.transparent,
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
                                      border: Border.all(width: .5, color: Colors.white)),
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
                                          )))))))).toList(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: const Text('Twist'),
                  onPressed: () {
                    setState(() {
                      twist.twistWord();
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                RaisedButton(
                  child: const Text('Clear'),
                  onPressed: () {
                    setState(() {
                      twist.resetSelection();
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                RaisedButton(
                  child: const Text('Enter'),
                  onPressed: () {
                    final w = twist.builtWord.join().toLowerCase().trim();
                    if (w.isEmpty) return;
                    if (twist.possibleWords.contains(w) && !twist.foundWords.contains(w)) {
                      setState(() {
                        twist.gameScore.onWordFound(w);
                        twist.foundWords.add(w);
                        twist.resetSelection();
                      });
                      final coins = _coinsStore.scoreChanged(twist.gameScore.score);
                      if (coins > 0) {
                        setState(() {
                          _coinsEarned = true;
                          _coinsAnimController.forward();
                        });
                      }
                    } else {
                      setState(() {
                        twist.gameScore.onWordMissed(w);
                      });
                      _shakeAnimController.reset();
                      _shakeAnimController.forward();
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

    if (_coinsEarned) {
      stackChildren.add(CoinsOverlay(
        controller: _coinsAnimController,
        screenSize: MediaQuery.of(context).size,
      ));
    }

    if (twist.gameMode != GameMode.unlimited && _gameTimer.isTimeExpired) {
      stackChildren.add(GameOverOverlay(
        controller: _gameOverAnimation,
        screenSize: MediaQuery.of(context).size,
      ));
    }

    return Scaffold(
        key: _scaffoldKey,
        appBar: twist.gameMode == null
            ? null
            : AppBar(
                title: twist.gameMode != GameMode.unlimited
                    ? Row(mainAxisSize: MainAxisSize.max, children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width / 3,
                            child: Padding(
                                padding: const EdgeInsets.only(left: 32),
                                child: AnimatedBuilder(
                                    animation: _timerScaleController,
                                    builder: (c, v) => Transform.scale(
                                          child: Text(
                                            _gameTimer.gameTime,
                                            textAlign: TextAlign.right,
                                            style: theme.textTheme.display1,
                                          ),
                                          scale: _timerScaleAnimation.value,
                                        )))),
                        SizedBox(
                            width: MediaQuery.of(context).size.width / 4,
                            child: IconButton(
                              icon: Icon(Icons.plus_one),
                              onPressed: _gameTimer.seconds > 0
                                  ? () async {
                                      if (await _confirmCoinSpend()) {
                                        _coinsStore.consumeCoins(kCoinsForOneMin);
                                        _gameTimer.addTime(60);
                                        setState(() {});
                                      }
                                    }
                                  : null,
                            )),
                      ])
                    : const Text('Word Twist'),
                centerTitle: true,
                actions: twist.gameMode != GameMode.unlimited
                    ? <Widget>[
                        Center(
                            child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: GameScoreWidget(
                                  score: twist.gameScore.score.toString(),
                                )))
                      ]
                    : null,
              ),
        drawer: MenuDrawer(
          width: MediaQuery.of(context).size.width,
          isGameOver: _gameTimer.isTimeExpired || twist.gameMode == GameMode.unlimited,
          isUnlimitedUnlocked: true,
          onNewGameClick: (m) {
            _createNewGame(m);
            Navigator.pop(context);
          },
          onSolveClick: () {
            setState(() {
              twist.solveAll();
              Navigator.pop(context);
            });
          },
          onStoreOpenClick: () {},
        ),
        body: twist.gameMode == null || _isLoading
            ? Stack(children: [
                FlareActor(
                  'assets/Background.flr',
                  alignment: Alignment.center,
                  fit: BoxFit.fill,
                  animation: 'rotate',
                ),
                Padding(
                    child: IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: () => _scaffoldKey.currentState.openDrawer(),
                    ),
                    padding: const EdgeInsets.only(top: 32, left: 16)),
                _isLoading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Container()
              ])
            : Transform(
                transform: Matrix4.translation(_getTranslation()),
                child: Stack(
                  children: stackChildren,
                )));
  }

  Future<bool> _confirmCoinSpend() {
    if (_userPrefs.getBool(_kDontAskAgianCoins) ?? false) {
      return Future.value(_coinsStore.coins >= kCoinsForOneMin);
    } else {
      final completer = new Completer<bool>();
      showDialog(
        context: context,
        builder: (c) => SpendCoinsAlertDialog(
              completer: completer,
              checkedCallback: (v) => _userPrefs.setBool(_kDontAskAgianCoins, true),
              coins: _coinsStore.coins,
            ),
      );
      return completer.future;
    }
  }
}

const _kDontAskAgianCoins = 'DontAskAgainCoins';

class SpendCoinsAlertDialog extends StatefulWidget {
  final Completer<bool> completer;
  final Function(bool) checkedCallback;
  final int coins;

  const SpendCoinsAlertDialog({Key key, this.completer, this.checkedCallback, this.coins}) : super(key: key);

  @override
  _SpendCoinsAlertDialogState createState() => _SpendCoinsAlertDialogState();
}

class _SpendCoinsAlertDialogState extends State<SpendCoinsAlertDialog> {
  bool checked = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Extend Time"),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text("Do you want to spend $kCoinsForOneMin coins to extend game time by 1 minute?",
                textAlign: TextAlign.start),
            Text(
              '\nCurrently you have ${widget.coins} coins.',
              textAlign: TextAlign.start,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            Row(
              children: <Widget>[
                Checkbox(
                  value: checked,
                  onChanged: (v) {
                    setState(() {
                      checked = v;
                    });
                    widget.checkedCallback(v);
                  },
                ),
                const Text("Don't ask again")
              ],
            )
          ]),
      actions: <Widget>[
        FlatButton(
          child: const Text("No"),
          onPressed: () {
            Navigator.of(context).pop();
            widget.completer.complete(false);
          },
        ),
        FlatButton(
          child: const Text("Yes"),
          onPressed: widget.coins >= kCoinsForOneMin
              ? () {
                  Navigator.of(context).pop();
                  widget.completer.complete(true);
                }
              : null,
        ),
      ],
    );
  }
}
