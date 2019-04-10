import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          colorScheme: ColorScheme.dark().copyWith(
              secondary: Colors.pinkAccent),
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

class _MyHomePageState extends State<MyHomePage> {
  TwistGame twist = new TwistGame(new WordsDataSource());
  bool _isLoading = false;
  GameTimer _timer;

  @override
  void initState() {
    _timer = new GameTimer(() {}, _onTimeTick);
    _createNewGame();
    super.initState();
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

  void _onTimeTick() {
    setState(() {
      _timer.gameTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                },
              )
            ],
          ),
        ),
        body: _isLoading
            ? Center(
          child: CircularProgressIndicator(),
        )
            : Padding(
          padding:
          EdgeInsets.only(bottom: 32, left: 16, right: 16, top: 42),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                _timer.gameTime,
                textAlign: TextAlign.center,
                style: theme.textTheme.display1,
              ),
              Expanded(
                  child: Padding(
                      padding: EdgeInsets.only(bottom: 32, top: 16),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                Iterable.generate(twist.builtWord.length).map((n) {
                  return Container(
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.white30, width: 1)),
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
                          style: TextStyle(fontSize: 30),
                        ),
                      ));
                }).toList(),
              ),
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
                                    .width - 64) /
                                    6,
                                onPressed: () {
                                  setState(() {
                                    twist.toggleSelect(n);
                                  });
                                },
                                child: Text(
                                  twist.isSelected(n) ? ' ' : twist[n],
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
                      final w =
                      twist.builtWord.join().toLowerCase().trim();
                      if (twist.possibleWords.contains(w.toLowerCase())) {
                        setState(() {
                          twist.foundWords.add(w);
                          twist.resetSelection();
                        });
                      }
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  )
                ],
              )
            ],
          ),
        ));
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
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: Iterable.generate(count, (n) {
        return Container(
            decoration: BoxDecoration(
                border: Border.all(width: 0.3, color: theme.highlightColor)),
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
