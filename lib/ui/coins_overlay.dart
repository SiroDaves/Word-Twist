import 'package:flutter/material.dart';

class CoinsOverlay extends StatelessWidget {
  CoinsOverlay({Key key, @required this.controller, @required this.screenSize, this.coinsEarned = 1})
      : _widthTween = Tween<double>(begin: 0, end: screenSize.width)
            .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)),
        _opacityTween = Tween<double>(begin: 0.4, end: 0.95)
            .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)),
        _fontSizeTween = Tween<double>(begin: 0, end: 56)
            .animate(CurvedAnimation(parent: controller, curve: Interval(0.4, 1, curve: Curves.bounceOut))),
        super(key: key);
  final Animation<double> _opacityTween;
  final Animation<double> _fontSizeTween;
  final Animation<double> _widthTween;
  final Animation<double> controller;
  final Size screenSize;
  final int coinsEarned;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (c, v) {
        return Container(
          child: SizedBox.expand(
            child: Center(
                child: Opacity(
              opacity: _opacityTween.value,
              child: Container(
                width: _widthTween.value,
                height: _widthTween.value,
                decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    coinsEarned == 1 ? '+ 1 Coin' : '+ $coinsEarned Coins',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .display2
                        .copyWith(color: Colors.white, fontSize: _fontSizeTween.value),
                  ),
                ),
              ),
            )),
          ),
        );
      },
    );
  }
}
