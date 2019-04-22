
import 'package:flutter/material.dart';

class GameScoreWidget extends StatefulWidget {
  final String score;

  GameScoreWidget({Key key, this.score}) : super(key: key);

  @override
  _GameScoreWidgetState createState() => _GameScoreWidgetState();
}

class _GameScoreWidgetState extends State<GameScoreWidget> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(GameScoreWidget oldWidget) {
    if (oldWidget.score != widget.score) {
      animationController
        ..value = 0
        ..forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    score = widget.score;
    animationController = new AnimationController(duration: const Duration(milliseconds: 400), vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          animationController.reverse();
          setState(() {
            score = widget.score;
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

