import 'package:flutter/material.dart';
import 'package:word_twist/game/coins_store.dart';

class SpendCoinsAlertDialog extends StatefulWidget {
  final String title;
  final String body;
  final Completer<bool> completer;
  final Function(bool) checkedCallback;
  final int coins;

  const SpendCoinsAlertDialog(
      {Key key,
      @required this.title,
      @required this.body,
      @required this.completer,
      @required this.checkedCallback,
      @required this.coins})
      : super(key: key);

  @override
  _SpendCoinsAlertDialogState createState() => _SpendCoinsAlertDialogState();
}

class _SpendCoinsAlertDialogState extends State<SpendCoinsAlertDialog> {
  bool checked = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.body, textAlign: TextAlign.start),
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
