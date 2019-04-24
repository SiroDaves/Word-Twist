import 'package:flutter/material.dart';
import 'package:word_twist/game/twist.dart';

class MenuDrawer extends StatefulWidget {
  final bool isGameOver;
  final Function onNewGameClick;
  final Function onStoreOpenClick;
  final Function onSolveClick;
  final double width;

  const MenuDrawer(
      {Key key,
      @required this.isGameOver,
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
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() {
            _showingNewGame = !_showingNewGame;
          });
          _controller.reverse();
        }
      });
    _offsetAnim = Tween<double>(begin: 0, end: widget.width * -1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
            Container(
              child: Column(
                children: <Widget>[
                  RaisedButton(
                      child: Text('Normal'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: widget.onNewGameClick),
                ],
              ),
            )
          ]
        : [
            RaisedButton(
              child: const Text('New Game'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => _controller.forward(),
            ),
            RaisedButton(
              child: const Text('In Game Store'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: widget.onStoreOpenClick,
            ),
            widget.isGameOver
                ? RaisedButton(
                    child: const Text('Solve'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: widget.onSolveClick,
                  )
                : SizedBox()
          ];
    return AnimatedBuilder(
        animation: _controller,
        builder: (c, v) => Container(
              padding: const EdgeInsets.only(top: 86, left: 32, right: 32, bottom: 32),
              child: Column(
                children: <Widget>[
                  Text(
                    'Word Twist',
                    style: theme.textTheme.display1,
                  ),
                  Divider(
                    color: Colors.white70,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  Transform.translate(
                    child: Column(mainAxisSize: MainAxisSize.min, children: children),
                    offset: Offset(_offsetAnim.value, 0),
                  )
                ],
              ),
            ));
  }
}
