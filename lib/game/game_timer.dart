import 'dart:async';

class GameTimer {
  final Function _onTimeExpired;
  final Function _onTimeTick;
  final int time;

  int _seconds = 2 * 60;
  StreamSubscription _streamSubscription;
  bool _paused = false;

  int get seconds => _seconds;

  String get gameTime {
    int mins = ((_seconds % 3600) ~/ 60);
    int seconds = _seconds % 60;
    return mins >= 10 ? '$mins' : '0$mins' + ':' + (seconds >= 10 ? '$seconds' : '0$seconds');
  }

  bool get isTimeExpired => _seconds == 0;
  bool get isPaused => _paused;

  GameTimer(this._onTimeExpired, this._onTimeTick, [this.time = 2 * 60]);

  void restartTimer() {
    dispose();
    _seconds = time;
    _streamSubscription = new Stream.periodic(new Duration(seconds: 1)).where((d) => !_paused).listen((d) {
      _seconds--;
      _onTimeTick();
      if (_seconds == 0) {
        _onTimeExpired();
        _streamSubscription.cancel();
      }
    });
  }

  void addTime(int seconds) {
    _seconds += seconds;
  }

  void stop() {
    dispose();
    _seconds = 0;
  }

  void togglePause() {
    _paused = !_paused;
  }

  void dispose() {
    _streamSubscription?.cancel();
  }
}