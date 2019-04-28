import 'package:flutter/material.dart';
import 'package:word_twist/game/twist.dart';

class MenuDrawer extends StatefulWidget {
  final bool canSolve;
  final Function(GameMode) onNewGameClick;
  final Function onStoreOpenClick;
  final Function onSolveClick;
  final double width;

  const MenuDrawer(
      {Key key,
      @required this.canSolve,
      @required this.width,
      @required this.onNewGameClick,
      @required this.onStoreOpenClick,
      @required this.onSolveClick})
      : super(key: key);

  @override
  _MenuDrawerState createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _offsetAnim;
  bool _showingNewGame = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 250), vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() {
            _showingNewGame = !_showingNewGame;
          });
          _controller.reverse();
        }
      });
    _offsetAnim = Tween<double>(begin: 0, end: (widget.width * -1) + widget.width / 4)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> children = _showingNewGame
        ? [
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => _controller.forward(),
                )
              ],
            ),
            Text(
              'New Game',
              style: theme.textTheme.headline,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
            GameModeHost(
              width: widget.width,
              gameMode: GameMode.normal,
              onNewGameClick: widget.onNewGameClick,
            ),
            Divider(),
            GameModeHost(
              width: widget.width,
              gameMode: GameMode.hard,
              onNewGameClick: widget.onNewGameClick,
            ),
            Divider(),
            Container(
              width: widget.width - 32,
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.white30), borderRadius: BorderRadius.circular(5)),
              padding: EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.all(8),
                          child: RaisedButton(
                              child: Text('Unlimited'),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onPressed: () => widget.onNewGameClick(GameMode.unlimited))),
                      Positioned(
                          left: 72,
                          top: 0,
                          child: Icon(
                              Icons.monetization_on,
                              size: 36,                                                        
                          ))
                    ],
                  ),
                  Divider(),
                  const Text(
                    'Unlimited time. No points.',
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            )
          ]
        : [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            RaisedButton(
              child: const Text('New Game'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => _controller.forward(),
            ),
            Divider(),
            RaisedButton(
              child: const Text('Coin Store'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: widget.onStoreOpenClick,
            ),
            Divider(),
            RaisedButton(
              child: const Text('Solve'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: widget.canSolve ? widget.onSolveClick : null,
            )
          ];
    return AnimatedBuilder(
        animation: _controller,
        builder: (c, v) => Container(
              width: widget.width * 0.7,
              color: const Color(0xFF1F1F1F),
              padding: const EdgeInsets.only(top: 48, left: 32, right: 32, bottom: 32),
              child: Column(
                children: <Widget>[
                  // IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context),),
                  Text(
                    'Word Twist',
                    style: theme.textTheme.display1,
                  ),
                  Divider(
                    color: Colors.white70,
                  ),
                  Transform.translate(
                    offset: Offset(_offsetAnim.value, 0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: children),
                  )
                ],
              ),
            ));
  }
}

class GameModeHost extends StatelessWidget {
  final double width;
  final Function(GameMode) onNewGameClick;
  final GameMode gameMode;

  const GameModeHost({Key key, @required this.width, @required this.onNewGameClick, @required this.gameMode})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    var btnText = '';
    var explanation = '';
    switch (gameMode) {
      case GameMode.normal:
        btnText = 'Normal';
        explanation = '2 minute time. Normal points for found words, no negative points on false words.';
        break;
      case GameMode.hard:
        btnText = 'Hard';
        explanation = '2 minute time. 150% points for found words, negative points on false words and on word twist.';
        break;
      case GameMode.unlimited:
        btnText = 'Unlimited';
        explanation = 'Unlimited time. No points';
        break;
      default:
    }
    return Container(
      width: width - 32,
      decoration: BoxDecoration(border: Border.all(color: Colors.white30), borderRadius: BorderRadius.circular(5)),
      padding: EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          RaisedButton(
              child: Text(btnText),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => onNewGameClick(gameMode)),
          Divider(),
          Text(
            explanation,
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}
