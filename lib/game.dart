import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';

import 'dart:async';
import 'scroll.dart';
import 'utils.dart';
import 'powerups.dart';

class Game extends StatefulWidget {
  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<Game> with WidgetsBindingObserver {

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

  void playMusic() async {
    musicCache = AudioCache(prefix: "audio/");
    instance = await musicCache.loop("bgmusic.mp3");
    await instance.setVolume(0.5);
  }

  void damage(TapDownDetails details) {
    if (!Utils.isDesktop()) {
      hitPlayer.pause();
      hitCache.play('audio/sword.mp3');
    }
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

        if (!Utils.isDesktop()) {
          coinCache.play('audio/coin.mp3');
        }
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

  double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  double listHeight(BuildContext context) {
    return width(context) >= 700 ? height(context) : height(context) / 2.8;
  }

  void buyPowerUp(int index) {
    if (!Utils.isDesktop()) {
      coinCache.play('audio/money.mp3');
    }
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
      return Container();
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

  Widget gameEngine(BuildContext context) {
    return width(context) >= 700
        ? Row(
      children: <Widget>[
        gamePanel(),
        sidePanel(),
      ],
    )
        : Column(
      children: <Widget>[
        gamePanel(),
        sidePanel(),
      ],
    );
  }

  Widget gamePanel() {
    return Align(
      // Stage panel
      alignment: Alignment.topCenter,
      child: Container(
        color: Colors.transparent,
        height: width(context) >= 700 ? height(context) : height(context) - listHeight(context),
        width: width(context) >= 700 ? width(context) >= 700 && width(context) <= 1000 ? 400 : 700 : width(context),
        child: Stack(
          children: <Widget>[
            SizedBox.expand(
              // Background
              child: Image.asset(
                skyAsset(),
                fit: BoxFit.cover,
              ),
            ),
            Align(
              child: Image.asset(
                stageAsset(),
                alignment: Alignment.bottomCenter,
                fit: BoxFit.fitWidth,
              ),
              alignment: Alignment.bottomCenter,
            ),
            Align(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: Image.asset(
                  bosses[bossIndex].asset,
                  height: 200.0,
                  fit: BoxFit.fill,
                  color: tap ? Color(0x80FFFFFF) : null,
                ),
              ),
              alignment: Alignment.bottomCenter,
            ),
            Align(
              child: Padding(
                padding: EdgeInsets.only(bottom: 50.0),
                child: Image.asset(
                  hero(),
                  alignment: Alignment.bottomCenter,
                ),
              ),
              alignment: Alignment.bottomCenter,
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
                        child: Text(
                          bosses[bossIndex].name + "  LV" + level.toString(),
                          style: Utils.textStyle(15.0),
                        ),
                      ),
                      Text(
                        damageBar.toInt().toString(),
                        style: Utils.textStyle(18.0),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "COINS: ",
                              style: Utils.textStyle(10.0),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                coins.toString(),
                                style: Utils.textStyle(10.0),
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
            GestureDetector(
              onTapDown: (TapDownDetails details) => damage(details),
              onTapUp: (TapUpDetails details) => hide(null),
              onTapCancel: () => hide(null),
            ),
            hitBox(),
          ],
        ),
      ),
    );
  }

  Widget sidePanel() {
    return Container(
      color: Colors.black,
      height: listHeight(context),
      width: width(context) >= 700
          ? width(context) >= 700 && width(context) <= 1000
          ? width(context) - 700 + 300
          : width(context) - 700
          : width(context),
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
                    child: Text(
                      "Power-Ups",
                      style: Utils.textStyle(12.0),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: share,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20.0, horizontal: 15.0),
                    child: Text(
                      "SHARE SCORE",
                      style: Utils.textStyle(12.0),
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
                padding: EdgeInsets.only(bottom: 20.0, left: 10.0, right: 10.0),
                itemCount: list.length,
                itemBuilder: (context, position) {
                  PowerUps powerUp = list[position];
                  int bgColor = !powerUp.bought && coins >= powerUp.coins
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
                              padding:
                              const EdgeInsets.symmetric(horizontal: 20.0),
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
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      !powerUp.bought ? "BUY" : "BOUGHT",
                                      style: Utils.textStyle(10.0),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 8.0,
                                        right: !powerUp.bought ? 2.0 : 0.0),
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
                              onPressed:
                              !powerUp.bought && coins >= powerUp.coins
                                  ? () => buyPowerUp(position)
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
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
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    if (!Utils.isDesktop()) {
      initPlayer();
      if (!musicPlaying) {
        musicPlaying = true;
        playMusic();
      }
    }

    damageBar = bosses[bossIndex].life.toDouble() * multiplier;
  }

  @override
  void dispose() {
    if (!Utils.isDesktop()) {
      if (musicPlaying && instance != null) {
        instance.stop();
      }
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!Utils.isDesktop()) {
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
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Material(child: gameEngine(context));
    });
  }
}
