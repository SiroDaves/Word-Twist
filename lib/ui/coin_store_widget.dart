import 'package:firebase_admob/firebase_admob.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:word_twist/game/coins_store.dart' show CoinsStore, kCoinsEarnedForRewardAd;
import 'package:flutter/services.dart' show PlatformException;
import 'package:word_twist/ui/coins_overlay.dart';

class CoinStoreWidget extends StatefulWidget {
  final CoinsStore coinsStore;

  const CoinStoreWidget({Key key, @required this.coinsStore}) : super(key: key);
  @override
  _CoinStoreWidgetState createState() => _CoinStoreWidgetState();
}

class _CoinStoreWidgetState extends State<CoinStoreWidget> with SingleTickerProviderStateMixin {
  AnimationController _coinsAnimController;
  bool _adLoaded = false;
  bool _coinsEarned = false;
  RewardedVideoAdEvent _event = RewardedVideoAdEvent.leftApplication;

  @override
  void initState() {
    _coinsAnimController = new AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() {
            _coinsEarned = false;
          });
          _coinsAnimController.value = 0;
        }
      });
    RewardedVideoAd.instance.listener = (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
      _event = event;
      if (event == RewardedVideoAdEvent.completed || event == RewardedVideoAdEvent.closed) {
        setState(() {
          _adLoaded = false;
        });
      }
      print(event);
      if (event == RewardedVideoAdEvent.rewarded) {
        setState(() {
          widget.coinsStore.onRewardedVideoPlayed();
          _coinsEarned = true;
          _coinsAnimController.forward();
        });
      }
    };
    RewardedVideoAd.instance
        .load(
            adUnitId: RewardedVideoAd.testAdUnitId,
            targetingInfo: MobileAdTargetingInfo(
              keywords: <String>['flutterio', 'beautiful apps'],
              contentUrl: 'https://flutter.io',
              childDirected: false,
              testDevices: <String>[], // Android emulators are considered test devices
            ))
        .then((v) {
      setState(() {
        _adLoaded = v;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _coinsAnimController.dispose();
    RewardedVideoAd.instance.listener = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coin Store'),
      ),
      body: Stack(children: [
        // FlareActor(
        //   'assets/stars.flr',
        //   animation: 'idle',
        //   fit: BoxFit.fill,
        // ),
        SafeArea(
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30), borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        'Coins are used for extending the game time or playing the game in unlimited time mode.\n\nEarn coins by playing the game.\n\nVideo ads reward 2 coins.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.subhead,
                      ),
                    ),                    
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Coins: ${widget.coinsStore.coins}',
                        style: Theme.of(context).textTheme.display1,
                      ),
                    ),
                    Divider(),
                    RaisedButton(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Rewarded Coins'),
                        // _adLoaded
                        //     ? Container()
                        //     : Container(
                        //       padding: EdgeInsets.only(left: 8),
                        //       child: SizedBox(
                        //         width: 20,
                        //         height: 20,
                        //         child: CircularProgressIndicator(
                        //           strokeWidth: 2,
                        //         )))
                      ]),
                      onPressed: _adLoaded ? _playRewardedVideo : null,
                    ),
                    Divider(),
                    RaisedButton(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Text('Buy 40 coins - \$0.49'),
                        onPressed: null),
                    Divider(),
                    RaisedButton(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Text('Buy 100 coins - \$0.99'),
                        onPressed: null),
                  ],
                ))),
        _coinsEarned
            ? CoinsOverlay(
                controller: _coinsAnimController,
                screenSize: MediaQuery.of(context).size,
                coinsEarned: kCoinsEarnedForRewardAd,
              )
            : Container()
      ]),
    );
  }

  void _playRewardedVideo() async {
    if (_event == RewardedVideoAdEvent.closed ||
        _event == RewardedVideoAdEvent.completed ||
        _event == RewardedVideoAdEvent.failedToLoad ||
        _event == RewardedVideoAdEvent.rewarded) return;
    try {
      RewardedVideoAd.instance.show();
    } on PlatformException {
      await Future.delayed(const Duration(milliseconds: 1000));
      _playRewardedVideo();
    }
  }
}
