import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:flare_flutter/flare_actor.dart";
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:word_twist/data/user_prefs.dart';
import 'package:word_twist/game/coins_store.dart';
import 'package:word_twist/game/twist.dart';
import 'package:word_twist/data/word_repo.dart';
import 'package:word_twist/game/user_prefs_impl.dart';
import 'package:word_twist/ui/coin_store_widget.dart';
import 'package:word_twist/ui/coins_overlay.dart';
import 'package:word_twist/ui/drawer.dart';
import 'package:word_twist/ui/game_over_overlay.dart';
import 'package:word_twist/ui/points.dart';
import 'package:word_twist/ui/spend_coins_dialog.dart';
import 'package:word_twist/ui/word_box.dart';
import 'package:word_twist/ui/word_holder.dart';

class WordTwistApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {    
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
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
      home: MainPage(title: 'Word Twist'),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver, TickerProviderStateMixin {
  final TwistGame twist = new TwistGame(new WordsDataSource());
  final UserPrefs _userPrefs = UserPrefsImpl.instance();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();

  int _coinsEarned = 0;

  bool _isLoading = false;
  bool _coinsChanged = false;

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
            _coinsChanged = false;
            _coinsEarned = 0;
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
  }

  void _onTimeTick() {
    setState(() {
      _gameTimer.gameTime;
    });
    if (_gameTimer.seconds < 30 && _timerScaleController.status == AnimationStatus.dismissed) {
      _timerScaleController.forward();
    }
  }

  bool _isGameOver() {
    final isOver = (twist.gameMode != GameMode.unlimited && _gameTimer.isTimeExpired) ||
        (twist.gameMode == GameMode.unlimited &&
            twist.possibleWords.length > 0 &&
            twist.foundWords.length == twist.possibleWords.length);
    if (isOver && _gameOverAnimController.status == AnimationStatus.dismissed) {
      _gameOverAnimController.forward();
    }
    return isOver;
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
    final size = MediaQuery.of(context).size;    
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
                    padding: EdgeInsets.symmetric(vertical: size.width < 500 ? 16 : 24),
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
              padding: EdgeInsets.only(top: size.width < 500 ? 16 : 24),
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
                                  height: size.width < 500 ? 40 : 46,
                                  width: size.width < 500 ? 38 : 42,
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
                      if (twist.gameMode == GameMode.unlimited && twist.isSolved) {
                        setState(() {
                          _coinsEarned = 20;
                          _coinsChanged = true;
                          _coinsAnimController.forward();
                          _coinsStore.coinEarned(_coinsEarned);
                        });
                      } else {
                        final coins = _coinsStore.scoreChanged(twist.gameScore.score);
                        if (coins > 0) {
                          setState(() {
                            _coinsEarned = coins;
                            _coinsChanged = true;
                            _coinsAnimController.forward();
                          });
                        }
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

    if (_coinsEarned > 0 && _coinsChanged) {
      stackChildren.add(CoinsOverlay(
        controller: _coinsAnimController,
        screenSize: size,
        coinsEarned: _coinsEarned,
      ));
    }

    if (_isGameOver()) {
      stackChildren.add(GameOverOverlay(
        controller: _gameOverAnimation,
        screenSize: size,
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
                            width: size.width / 3,
                            child: Padding(
                                padding: const EdgeInsets.only(left: 16),
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
                        Builder(
                            builder: (c) => SizedBox(
                                width: size.width / 5,
                                child: IconButton(
                                  icon: Icon(Icons.plus_one),
                                  onPressed: _gameTimer.seconds > 0
                                      ? () async {
                                          if (_coinsStore.coins < kCoinsForOneMin) {
                                            Scaffold.of(c).showSnackBar(SnackBar(
                                              content: Text(
                                                'Not enough coins to extend the game time.',
                                                textAlign: TextAlign.center,
                                              ),
                                            ));
                                          } else if (await _confirmCoinSpend()) {
                                            _coinsStore.consumeCoins(kCoinsForOneMin);
                                            _gameTimer.addTime(60);
                                            setState(() {});
                                          }
                                        }
                                      : null,
                                ))),
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
        drawer: Builder(
            builder: (c) => MenuDrawer(
                  coinsStore: _coinsStore,
                  width: size.width,
                  canSolve: !twist.isSolved && (_gameTimer.isTimeExpired || twist.gameMode == GameMode.unlimited),
                  onNewGameClick: (m) async {
                    if (m == GameMode.unlimited) {
                      if (_coinsStore.coins < kCoinsToPlayUnlimited) {
                        Navigator.pop(context);
                        Scaffold.of(c).showSnackBar(SnackBar(
                          content: Text(
                            'Not enough coins to play Unlimited mode.',
                            textAlign: TextAlign.center,
                          ),
                        ));
                      } else if (await _confirmPlayUnlimited()) {
                        _coinsStore.consumeCoins(kCoinsToPlayUnlimited);
                        _createNewGame(m);
                        Navigator.pop(context);
                      }
                    } else {
                      _createNewGame(m);
                      Navigator.pop(context);
                    }
                  },
                  onSolveClick: () {
                    if (_gameOverAnimController.status == AnimationStatus.completed &&
                        twist.gameMode == GameMode.unlimited) _gameOverAnimController.reset();
                    setState(() {
                      twist.solveAll();
                      Navigator.pop(context);
                    });
                  },
                  onStoreOpenClick: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (c) => CoinStoreWidget(
                                  coinsStore: _coinsStore,
                                )));
                  },
                )),
        body: twist.gameMode == null || _isLoading
            ? Stack(children: [
                FlareActor(
                  'assets/Background.flr',
                  alignment: Alignment.center,
                  fit: BoxFit.fill,
                  animation: 'rotate',
                ),
                twist.gameMode == null
                    ? Padding(
                        child: IconButton(
                          icon: Icon(Icons.menu),
                          onPressed: () => _scaffoldKey.currentState.openDrawer(),
                        ),
                        padding: const EdgeInsets.only(top: 32, left: 16))
                    : Container(),
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
      return Future.value(true);
    } else {
      final completer = new Completer<bool>();
      showDialog(
        context: context,
        builder: (c) => SpendCoinsAlertDialog(
              completer: completer,
              checkedCallback: (v) => _userPrefs.setBool(_kDontAskAgianCoins, v),
              coins: _coinsStore.coins,
              title: 'Extend Time',
              body: 'Do you want to spend $kCoinsForOneMin coins to extend game time by 1 minute?',
            ),
      );
      return completer.future;
    }
  }

  Future<bool> _confirmPlayUnlimited() {
    if (_userPrefs.getBool(_kDontAskAgianUnlimited) ?? false) {
      return Future.value(true);
    } else {
      final completer = new Completer<bool>();
      showDialog(
        context: context,
        builder: (c) => SpendCoinsAlertDialog(
              completer: completer,
              checkedCallback: (v) => _userPrefs.setBool(_kDontAskAgianUnlimited, v),
              coins: _coinsStore.coins,
              title: 'Play Unlimited Mode',
              body: 'Do you want to spend $kCoinsToPlayUnlimited coins to to play the game in Unlimited mode?',
            ),
      );
      return completer.future;
    }
  }
}

const _kDontAskAgianCoins = 'DontAskAgainCoins';
const _kDontAskAgianUnlimited = 'DontAskAgainUnlimited';
