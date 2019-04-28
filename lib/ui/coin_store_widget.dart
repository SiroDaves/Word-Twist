import 'package:firebase_admob/firebase_admob.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:word_twist/game/coins_store.dart';

class CoinStoreWidget extends StatefulWidget {
  final CoinsStore coinsStore;

  const CoinStoreWidget({Key key, @required this.coinsStore}) : super(key: key);
  @override
  _CoinStoreWidgetState createState() => _CoinStoreWidgetState();
}

class _CoinStoreWidgetState extends State<CoinStoreWidget> {
  bool _adLoaded = false;
  @override
  void initState() {
    RewardedVideoAd.instance.listener = (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
      if (event == RewardedVideoAdEvent.loaded) {
        setState(() {
          _adLoaded = true;
        });
      } else if (event == RewardedVideoAdEvent.completed) {
        setState(() {
          _adLoaded = false;
        });
      }
      print(event);
      if (event == RewardedVideoAdEvent.rewarded) {
        setState(() {
          print('coins earned' + rewardAmount.toString());
        });
      }
    };
    RewardedVideoAd.instance
        .load(
            adUnitId: RewardedVideoAd.testAdUnitId,
            targetingInfo: MobileAdTargetingInfo(
              keywords: <String>['flutterio', 'beautiful apps'],
              contentUrl: 'https://flutter.io',
              birthday: DateTime.now(),
              childDirected: false,
              designedForFamilies: false,
              gender: MobileAdGender.male, // or MobileAdGender.female, MobileAdGender.unknown
              testDevices: <String>[], // Android emulators are considered test devices
            ))
        .then((v) {
      if (v) {
        try {
          RewardedVideoAd.instance.show();
        } catch (e) {}
      }
    });
    super.initState();
  }

  @override
  void dispose() {
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
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30), borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        'Coins are used for extending the game time or playing the game in unlimited time mode.\n\nEarn coins by playing the game. For every 100 points you earn 1 coin.\n\nVideo ads reward 2 coins.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.subhead,
                      ),
                    ),
                    Divider(),
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
                      onPressed: _adLoaded
                          ? () {
                              RewardedVideoAd.instance.show();
                            }
                          : null,
                    ),
                    Divider(),
                    RaisedButton(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Text('Buy 40 coins - \$0.49'),
                        onPressed: () {}),
                    Divider(),
                    RaisedButton(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Text('Buy 100 coins - \$0.99'),
                        onPressed: () {}),
                  ],
                )))
      ]),
    );
  }
}
