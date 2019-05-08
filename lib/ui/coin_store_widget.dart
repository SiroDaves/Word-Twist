import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:word_twist/game/coins_store.dart' show CoinsStore, kCoinsEarnedForRewardAd;
import 'package:word_twist/ui/admob_config.dart';
import 'package:word_twist/ui/coins_overlay.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

class CoinStoreWidget extends StatefulWidget {
  final CoinsStore coinsStore;

  const CoinStoreWidget({Key key, @required this.coinsStore}) : super(key: key);
  @override
  _CoinStoreWidgetState createState() => _CoinStoreWidgetState();
}

const Set<String> _kPurchaseIds = {
  'com.markodevcic.wordtwist.100coins',
};

class _CoinStoreWidgetState extends State<CoinStoreWidget> with SingleTickerProviderStateMixin {
  AnimationController _coinsAnimController;
  bool _adLoaded = false;
  bool _coinsEarned = false;
  bool _rewarded = false;
  bool _storeAvailable = false;

  int _coinsAmount = 0;

  RewardedVideoAdEvent _event = RewardedVideoAdEvent.leftApplication;
  StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _productDetails = [];

  @override
  void initState() {
    _coinsAnimController = new AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() {
            _coinsEarned = false;
            _coinsAmount = 0;
          });
          _coinsAnimController.value = 0;
        }
      });
    RewardedVideoAd.instance.listener = (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
      _event = event;
      print(event);
      if (event == RewardedVideoAdEvent.rewarded) {
        _rewarded = true;
      } else if (event == RewardedVideoAdEvent.loaded) {
        setState(() {
          _adLoaded = true;
        });
      } else if (event == RewardedVideoAdEvent.completed || event == RewardedVideoAdEvent.closed) {
        setState(() {
          if (_rewarded) {
            _coinsEarned = true;
            _coinsAmount = kCoinsEarnedForRewardAd;
            widget.coinsStore.onRewardedVideoPlayed();
            _coinsAnimController.forward();
            _adLoaded = false;
          }
        });
      }
    };
    RewardedVideoAd.instance.load(
        adUnitId: AdMobConfig.getRewardedAdId,
        targetingInfo: MobileAdTargetingInfo(
          childDirected: false,
          testDevices: <String>[],
        ));

    final Stream purchaseUpdates = InAppPurchaseConnection.instance.purchaseUpdatedStream;
    _subscription = purchaseUpdates.listen(_handlePurchaseUpdates);

    InAppPurchaseConnection.instance.isAvailable().then((v) async {
      setState(() {
        _storeAvailable = v;
      });
      if (v) {
        final respons = await InAppPurchaseConnection.instance.queryProductDetails(_kPurchaseIds);
        setState(() {
          _productDetails = respons.productDetails;
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() async {
    _coinsAnimController.dispose();
    RewardedVideoAd.instance.listener = null;
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coin Store'),
      ),
      body: Stack(children: [
        SafeArea(
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: SingleChildScrollView(
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
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Divider(),
                    RaisedButton(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rewarded Coins'),
                            _rewarded || _adLoaded
                                ? Container()
                                : Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(),
                                    ))
                          ]),
                      onPressed: _adLoaded ? _playRewardedVideo : null,
                    ),
                    Divider(),
                    if (_storeAvailable)
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        for (var p in _productDetails)
                          RaisedButton(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: Text('${p.description} - ${p.price}'),
                              onPressed: () {
                                InAppPurchaseConnection.instance.buyConsumable(
                                    purchaseParam:
                                        PurchaseParam(productDetails: p));
                              })
                      ])
                  ],
                )))),
        if (_coinsEarned)
          CoinsOverlay(
            controller: _coinsAnimController,
            screenSize: MediaQuery.of(context).size,
            coinsEarned: _coinsAmount,
          )
      ]),
    );
  }

  void _playRewardedVideo() {
    if (_event == RewardedVideoAdEvent.closed ||
        _event == RewardedVideoAdEvent.completed ||
        _event == RewardedVideoAdEvent.failedToLoad ||
        _event == RewardedVideoAdEvent.rewarded) return;
    RewardedVideoAd.instance.show().catchError((e) {
      print(e);
    });
  }

  void _handlePurchaseUpdates(purchases) {
    List<PurchaseDetails> details = purchases as List<PurchaseDetails>;
    details.forEach((d) {
      print(d.status);
      print(d.productID);
      print(d.skPaymentTransaction?.error?.domain);
      print(d.skPaymentTransaction?.error?.userInfo);
      print(d.skPaymentTransaction?.error?.code);      
      if (d.status == PurchaseStatus.purchased) {
          setState(() {
            _coinsAmount = 100;
            _coinsEarned = true;
          });
      }
    });
  }
}
