import 'package:flutter/material.dart';

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