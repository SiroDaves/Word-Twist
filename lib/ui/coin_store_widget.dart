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
      }
      print(event);
      if (event == RewardedVideoAdEvent.rewarded) {
        setState(() {
          print('coins earned' + rewardAmount.toString());
        });
      }
    };
    RewardedVideoAd.instance.load(
        adUnitId: RewardedVideoAd.testAdUnitId,
        targetingInfo: MobileAdTargetingInfo(
          keywords: <String>['flutterio', 'beautiful apps'],
          contentUrl: 'https://flutter.io',
          birthday: DateTime.now(),
          childDirected: false,
          designedForFamilies: false,
          gender: MobileAdGender.male, // or MobileAdGender.female, MobileAdGender.unknown
          testDevices: <String>[], // Android emulators are considered test devices
        ));
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
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30), borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        'Earn coins by playing the game. For every 100 points you earn 1 coin.\n\nVideo ads reward 2 coins.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.subhead,
                      ),
                    ),
                    Text('Coins: ${widget.coinsStore.coins}'),
                    RaisedButton(
                      child: Text('Rewarded Coins'),
                      onPressed: _adLoaded
                          ? () {
                              RewardedVideoAd.instance.show();
                            }
                          : null,
                    )
                  ],
                )))
      ]),
    );
  }
}
