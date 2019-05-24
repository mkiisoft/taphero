import 'package:flutter/material.dart';
import 'dart:async';
import 'scroll.dart';
import 'utils.dart';
import 'powerups.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share/share.dart';

class IntroApp extends StatefulWidget {
  @override
  _IntroAppState createState() => _IntroAppState();
}

class _IntroAppState extends State<IntroApp> with WidgetsBindingObserver {
  static String skyAsset() => "assets/background/sky.png";

  static String stageAsset() => "assets/background/front.png";

  static var multiplier = 1.0;
  static var damageDefault = 980.0;
  static var damageBar = damageDefault;
  static var damageUser = 30.0;

  var list = Utils.getPowerUps();
  var coins = 0;

  var bosses = Utils.getBosses();
  var bossIndex = 0;

  var level = 1;

  var tap = false;

  var xAxis = 0.0;
  var yAxis = 0.0;

  var earnedCoin = false;

  AudioPlayer hitPlayer;
  AudioCache hitCache;

  AudioPlayer coinPlayer;
  AudioCache coinCache;

  static AudioCache musicCache;
  static AudioPlayer instance;

  static var musicPlaying = false;

  void initPlayer() {
    hitPlayer = AudioPlayer();
    hitCache = AudioCache(fixedPlayer: hitPlayer);

    coinPlayer = AudioPlayer();
    coinCache = AudioCache(fixedPlayer: coinPlayer);
  }

  void damage(TapDownDetails details) {
    hitPlayer.pause();
    hitCache.play('audio/sword.mp3');
    setState(() {
      xAxis = details.globalPosition.dx - 40.0;
      yAxis = details.globalPosition.dy - 80.0;
      tap = true;

      if (damageBar - damageUser <= 0) {
        damageBar = damageBar - damageUser;
        coins = coins + 20;
        multiplier = (bossIndex + 1 >= bosses.length) ? multiplier * 1.25 : multiplier;
        level = (bossIndex + 1 >= bosses.length) ? ++level : level;
        bossIndex = (bossIndex + 1 >= bosses.length) ? 0 : ++bossIndex;
        damageBar = bosses[bossIndex].life.toDouble() * multiplier;
        earnedCoin = true;
        coinCache.play('audio/coin.mp3');
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            earnedCoin = false;
          });
        });
      } else {
        damageBar = damageBar - damageUser;
      }
    });
  }

  void hide(TapUpDetails details) {
    setState(() {
      tap = false;
    });
  }

  double listHeight(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    return height / 2.8;
  }

  void buyPowerUp(int index) {
    coinCache.play('audio/money.mp3');
    setState(() {
      if (coins >= list[index].coins) {
        coins = coins - list[index].coins;
        list[index].bought = true;
        damageUser = damageUser * list[index].multiplier;
      }
    });
  }

  Widget coinVisibility(bool bought) {
    if (bought) {
      return Container(
        width: 0.0,
        height: 0.0,
      );
    } else {
      return Image.asset(
        "assets/elements/coin.png",
        height: 13.0,
      );
    }
  }

  Widget earnedCoins() {
    if (earnedCoin) {
      return Padding(
        padding: const EdgeInsets.only(left: 5.0),
        child: Material(
          color: Colors.transparent,
          child: Text(
            "+20",
            style: Utils.textStyle(10.0, color: Colors.yellow),
          ),
        ),
      );
    } else {
      return Container(
        width: 0.0,
        height: 0.0,
      );
    }
  }

  Widget hitBox() {
    if (tap) {
      return Positioned(
        top: yAxis,
        left: xAxis,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Material(
                color: Colors.transparent,
                child: StrokeText(
                  "-${damageUser.toInt().toString()}",
                  fontSize: 14.0,
                  fontFamily: "Gameplay",
                  color: Colors.red,
                  strokeColor: Colors.black,
                  strokeWidth: 1.0,
                ),
              ),
            ),
            Image.asset(
              "assets/elements/hit.png",
              fit: BoxFit.fill,
              height: 80.0,
              width: 80.0,
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: 0.0,
        height: 0.0,
      );
    }
  }

  String hero() {
    return tap ? "assets/character/attack.png" : "assets/character/idle.png";
  }
  
  void share() {
    Share.share("Tap Hero: I survive until ${bosses[bossIndex].name} LV$level! Now is your turn!");
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    initPlayer();
    if (!musicPlaying) {
      musicPlaying = true;
      playMusic();
    }

    damageBar = bosses[bossIndex].life.toDouble() * multiplier;
  }

  @override
  void dispose() {
    if (musicPlaying && instance != null) {
      instance.stop();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive && instance != null) {
      if (musicPlaying) {
        instance.stop();
        musicPlaying = false;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!musicPlaying) {
        musicPlaying = true;
        playMusic();
      }
    }
  }

  void playMusic() async {
    musicCache = AudioCache(prefix: "audio/");
    instance = await musicCache.loop("bgmusic.mp3");
    instance.setVolume(0.5);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.loose,
        children: <Widget>[
          Image.asset(
            skyAsset(),
            fit: BoxFit.cover,
            height: MediaQuery.of(context).size.height,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black,
              height: listHeight(context),
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20.0, horizontal: 15.0),
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                "Power-Ups",
                                style: Utils.textStyle(12.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => share(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20.0, horizontal: 15.0),
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                "SHARE SCORE",
                                style: Utils.textStyle(12.0),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: GlowBehavior(),
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                            bottom: 20.0, left: 10.0, right: 10.0),
                        itemCount: list.length,
                        itemBuilder: (context, position) {
                          PowerUps powerUp = list[position];
                          int bgColor =
                              !powerUp.bought && coins >= powerUp.coins
                                  ? 0xFF808080
                                  : !powerUp.bought ? 0xFF505050 : 0xFF202020;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 5.0,
                            ),
                            child: Card(
                              color: Color(bgColor),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0),
                                      child: Text(
                                        powerUp.name,
                                        style: Utils.textStyle(11.0),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 20.0),
                                    child: RaisedButton(
                                      child: Row(
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: Text(
                                              !powerUp.bought
                                                  ? "BUY"
                                                  : "BOUGTH",
                                              style: Utils.textStyle(10.0),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                left: 8.0,
                                                right: !powerUp.bought
                                                    ? 2.0
                                                    : 0.0),
                                            child: Text(
                                              !powerUp.bought
                                                  ? powerUp.coins.toString()
                                                  : "",
                                              style: Utils.textStyle(10.0),
                                            ),
                                          ),
                                          coinVisibility(powerUp.bought),
                                        ],
                                      ),
                                      color: Colors.deepPurpleAccent,
                                      disabledColor: Colors.deepPurple,
                                      onPressed: !powerUp.bought &&
                                              coins >= powerUp.coins
                                          ? () => buyPowerUp(position)
                                          : null,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              color: Colors.transparent,
              height: MediaQuery.of(context).size.height - listHeight(context),
              child: Image.asset(
                stageAsset(),
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 100.0),
            child: Image.asset(
              bosses[bossIndex].asset,
              height: 200.0,
              fit: BoxFit.fill,
              color: tap ? Color(0x80FFFFFF) : null,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 80.0),
            child: Image.asset(
              hero(),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 30.0),
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          bosses[bossIndex].name + "  LV" + level.toString(),
                          style: Utils.textStyle(15.0),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: Text(
                        damageBar.toInt().toString(),
                        style: Utils.textStyle(18.0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              "COINS: ",
                              style: Utils.textStyle(10.0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 5.0),
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                coins.toString(),
                                style: Utils.textStyle(10.0),
                              ),
                            ),
                          ),
                          Image.asset(
                            "assets/elements/coin.png",
                            height: 12.2,
                          ),
                          earnedCoins(),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTapDown: (TapDownDetails details) => damage(details),
              onTapUp: (TapUpDetails details) => hide(null),
              onTapCancel: () => hide(null),
              child: Container(
                color: Colors.transparent,
                height:
                    MediaQuery.of(context).size.height - listHeight(context),
              ),
            ),
          ),
          hitBox(),
        ],
      ),
    );
  }
}
