import 'package:flutter/material.dart';
import 'package:word_twist/game/twist.dart';
import 'package:word_twist/ui/word_twist_app.dart';

class WordHolder extends StatefulWidget {
  final Function onTap;
  final List<String> builtWord;
  final int foundWords;

  const WordHolder({Key key, this.onTap, this.foundWords, this.builtWord}) : super(key: key);

  @override
  _WordHolderState createState() => _WordHolderState();
}

class _WordHolderState extends State<WordHolder> with SingleTickerProviderStateMixin {
  AnimationController animationController;
  Animation<double> scaleAnimation;
  Animation<double> borderAnimation;
  List<String> letters;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
        animation: animationController,
        builder: (c, v) => Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: widget.onTap,
                child: Transform.scale(
                    scale: scaleAnimation.value,
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: borderAnimation.value),
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: Iterable.generate(letters.length)
                              .map((n) => Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Container(
                                      height: size.width < kWidthLimit ? 42 : 46,
                                      child: Center(
                                          child: AnimatedDefaultTextStyle(
                                        child: Text(
                                          letters[n],
                                        ),
                                        duration: Duration(milliseconds: 250),
                                        curve: Curves.easeInSine,
                                        style: letters[n] == kSpace
                                            ? TextStyle(fontSize: 0).copyWith(color: Colors.white)
                                            : TextStyle(fontSize: 32).copyWith(color: Colors.white),
                                      )))))
                              .toList(),
                        ))))));
  }

  @override
  void didUpdateWidget(WordHolder oldWidget) {
    if (oldWidget.foundWords < widget.foundWords) {
      animationController
        ..value = 0
        ..forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    letters = widget.builtWord;
    animationController = new AnimationController(duration: const Duration(milliseconds: 300), vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          animationController.reverse();
          setState(() {
            letters = widget.builtWord;
          });
        }
      });
    scaleAnimation = new Tween<double>(begin: 1, end: 1.1).animate(animationController);
    borderAnimation = new Tween<double>(begin: 0.5, end: 4).animate(animationController);
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}
