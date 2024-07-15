import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tap_hero/bordered_text.dart';

import 'button.dart';
import 'dart:async';
import 'scroll.dart';
import 'utils.dart';
import 'powerups.dart';
import 'route.dart';
import 'welcome.dart';
import 'gamepad.dart';

class Game extends StatefulWidget {
  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<Game>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  AnimationController? controller;
  int duration = 1000 * 30;
  late int durationBackup;

  static const MethodChannel _channel = const MethodChannel('gamepad');

  static String skyAsset() => "assets/background/sky.png";

  static String stageAsset() => "assets/background/front.png";

  static var multiplier = 1.0;
  static var damageDefault = 980.0;
  static var damageBar = damageDefault;
  static var damageUser = 30.0;
  static var addedDuration = 1000 * 10;

  var list = Utils.getPowerUps();
  var coins = 0;

  var bosses = Utils.getBosses();
  var bossIndex = 0;

  var level = 1;

  var tap = false;

  var xAxis = 0.0;
  var yAxis = 0.0;

  var earnedCoin = false;

  late AudioPlayer hitPlayer;
  late AudioPlayer coinPlayer;

  AudioPlayer? musicPlayer;

  var musicPlaying = false;

  VoidCallback? onEarnTime;

  var gameOver = false;

  Color clockColor = const Color(0xFF67AC5B);

  bool? _gamepadConnected = false;

  String get timerString {
    Duration duration = controller!.duration! * controller!.value;
    return '${(duration.inMinutes).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  void initPlayer() {
    hitPlayer = AudioPlayer();
    coinPlayer = AudioPlayer();
  }

  void playMusic() async {
    musicPlayer = AudioPlayer();
    await musicPlayer!.setVolume(0.5);
    await musicPlayer!.setReleaseMode(ReleaseMode.loop);
    await musicPlayer!.play(AssetSource('audio/bgmusic.mp3'));
  }

  void playGameOver() async {
    musicPlayer = AudioPlayer();
    await musicPlayer!.setVolume(0.5);
    await musicPlayer!.setReleaseMode(ReleaseMode.loop);
    await musicPlayer!.play(AssetSource('audio/game_over.mp3'));
  }

  void damage(TapDownDetails? details) {
    if (!Utils.isDesktop()) {
      hitPlayer.pause();
      hitPlayer.play(AssetSource('audio/sword.mp3'));
    }
    setState(() {
      if (details != null) {
        xAxis = details.globalPosition.dx - 40.0;
        yAxis = details.globalPosition.dy - 80.0;
      }

      tap = true;

      if (damageBar - damageUser <= 0) {
        damageBar = damageBar - damageUser;
        coins = coins + 20;
        multiplier =
            (bossIndex + 1 >= bosses.length) ? multiplier * 1.25 : multiplier;
        level = (bossIndex + 1 >= bosses.length) ? ++level : level;
        addedDuration =
            (bossIndex + 1 >= bosses.length) ? 1000 * 20 : 1000 * 10;
        bossIndex = (bossIndex + 1 >= bosses.length) ? 0 : ++bossIndex;
        damageBar = bosses[bossIndex].life.toDouble() * multiplier;
        earnedCoin = true;
        onEarnTime?.call();
        if (!Utils.isDesktop()) {
          coinPlayer.play(AssetSource('audio/coin.mp3'));
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

  void hide(TapUpDetails? details) {
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
      coinPlayer.play(AssetSource('audio/money.mp3'));
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
      return Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: Image.asset(
          "assets/elements/coin.png",
          width: 13,
          height: 13,
        ),
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
      return const SizedBox(
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
          children: [
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
      return Container();
    }
  }

  String _hero() {
    return tap ? "assets/character/attack.png" : "assets/character/idle.png";
  }

  void _share() {
    Share.share("Tap Hero: I survive until ${bosses[bossIndex].name} LV$level! Now is your turn!");
  }

  Widget _gameEngine(BuildContext context) {
    return width(context) >= 700
        ? Row(
            children: [
              gamePanel(),
              sidePanel(),
            ],
          )
        : Column(
            children: [
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
        height: width(context) >= 700
            ? height(context)
            : height(context) - listHeight(context),
        width: width(context) >= 700
            ? width(context) >= 700 && width(context) <= 900
                ? 400
                : width(context) - 400
            : width(context),
        child: Stack(
          children: [
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
                  height:
                      width(context) / 2.5 < 380 ? width(context) / 2.5 : 380,
                  fit: BoxFit.fill,
                  color: tap ? const Color(0x80FFFFFF) : null,
                ),
              ),
              alignment: Alignment.bottomCenter,
            ),
            Align(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Image.asset(
                  _hero(),
                  height: width(context) / 6 < 160 ? width(context) / 6 : 160,
                  fit: BoxFit.fill,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              alignment: Alignment.bottomCenter,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Stack(
                            children: [
                              FancyButton(
                                child: Text(
                                  "      $timerString",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black87,
                                    fontFamily: "Gameplay",
                                  ),
                                ),
                                size: 20,
                                color: const Color(0xFFEFF3ED),
                              ),
                              FancyButton(
                                child: const Icon(
                                  Icons.watch_later,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                                size: 20,
                                color: clockColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: BorderedText(
                            strokeWidth: 4,
                            child: Text(
                              bosses[bossIndex].name + "  LV" + level.toString(),
                              style: Utils.textStyle(15.0),
                            ),
                          ),
                        ),
                        FancyButton(
                          child: Text(
                            "LIFE:  ${damageBar.toInt().toString()}",
                            style: Utils.textStyle(18.0),
                          ),
                          size: 18,
                          color: const Color(0xFFCA3034),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BorderedText(
                                strokeWidth: 4,
                                child: Text(
                                  "COINS: ",
                                  style: Utils.textStyle(10.0),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: BorderedText(
                                  strokeWidth: 4,
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
            ),
            GestureDetector(
              onTapDown: (TapDownDetails details) => damage(details),
              onTapUp: (TapUpDetails details) => hide(null),
              onTapCancel: () => hide(null),
            ),
            _gamepadConnected! ? Container() : hitBox(),
            _close(),
          ],
        ),
      ),
    );
  }

  Widget _close() {
    return Padding(
      padding: const EdgeInsets.only(left: 15, top: 45),
      child: FancyButton(
        child: const Text(
          "X",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Gameplay',
          ),
        ),
        size: 25,
        color: const Color(0xFFCA3034),
        onPressed: () {
          Navigator.of(context).pushReplacement(
            InitRoute(Welcome()),
          );
        },
      ),
    );
  }

  Widget sidePanel() {
    return Container(
      color: Colors.black,
      height: listHeight(context),
      width: width(context) >= 700
          ? width(context) >= 700 && width(context) <= 900
              ? width(context) - 700 + 300
              : 400
          : width(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 15,
                    ),
                    child: FancyButton(
                      size: 20,
                      color: const Color(0xFF67AC5B),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "SHARE SCORE",
                          style: Utils.textStyle(12.0),
                        ),
                      ),
                      onPressed: _share,
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: GlowBehavior(),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20.0, left: 10.0, right: 10.0),
                itemCount: list.length,
                itemBuilder: (context, position) {
                  PowerUps powerUp = list[position];
                  int bgColor = !powerUp.bought && coins >= powerUp.coins
                      ? 0xFF808080
                      : !powerUp.bought
                          ? 0xFF505050
                          : 0xFF202020;

                  return swordElement(bgColor, powerUp, position);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget swordElement(int bgColor, PowerUps powerUp, int position) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5.0,
      ),
      child: SizedBox(
        height: 70,
        child: Card(
          color: Color(bgColor),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    powerUp.name,
                    style: Utils.textStyle(11.0),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                child: FancyButton(
                  size: 20,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 10.0, bottom: 2, top: 2),
                        child: Text(
                          !powerUp.bought ? "BUY" : "BOUGHT",
                          style: Utils.textStyle(13.0,
                              color:
                                  !powerUp.bought ? Colors.white : Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: 8.0, right: !powerUp.bought ? 2.0 : 0.0),
                        child: Text(
                          !powerUp.bought ? powerUp.coins.toString() : "",
                          style: Utils.textStyle(13.0),
                        ),
                      ),
                      coinVisibility(powerUp.bought),
                    ],
                  ),
                  color: !powerUp.bought && coins >= powerUp.coins
                      ? Colors.deepPurpleAccent
                      : Colors.deepPurple,
                  onPressed: !powerUp.bought && coins >= powerUp.coins
                      ? () => buyPowerUp(position)
                      : null,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void initClock({required int add}) {
    if (controller == null) {
      durationBackup = duration;
    } else {
      Duration currentDuration = controller!.duration! * controller!.value;
      durationBackup = currentDuration.inMilliseconds;
      controller!.stop();
    }

    controller = null;
    controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: durationBackup + add));
    controller!
        .reverse(from: controller!.value == 0.0 ? 1.0 : controller!.value);
    controller!.addListener(() {
      setState(() {
        timerString;

        Duration duration = controller!.duration! * controller!.value;

        if (duration.inSeconds >= 0 && (duration.inSeconds % 60) > 20) {
          clockColor = const Color(0xFF67AC5B);
        }

        if (duration.inSeconds == 0 && (duration.inSeconds % 60) < 20) {
          clockColor = const Color(0xFFED6337);
        }

        if (duration.inSeconds == 0 && (duration.inSeconds % 60) < 10) {
          clockColor = const Color(0xFFCA3034);
        }
      });
    });
    controller!.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          gameOver = true;
        });
      }
    });
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

    initClock(add: 0);
    onEarnTime = () {
      initClock(add: addedDuration);
    };
    damageBar = bosses[bossIndex].life.toDouble() * multiplier;

    GamePad.isGamePadConnected.then((connected) {
      setState(() {
        _gamepadConnected = connected;
      });
    });

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "keyCode":
          var pair = Utils.mapToPair(Map<int, bool>.from(call.arguments));
          setState(() {
            if (!gameOver) {
              if (pair.value) {
                switch (GamePad.switchMap[pair.key]) {
                  case "A":
                    damage(null);
                    break;
                }
              } else {
                hide(null);
              }
            }
          });
          break;
      }
    });
  }

  @override
  void dispose() {
    if (!Utils.isDesktop()) {
      if (musicPlaying && musicPlayer != null) {
        musicPlayer!.stop();
        musicPlaying = false;
      }
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!Utils.isDesktop()) {
      if (state == AppLifecycleState.inactive && musicPlayer != null) {
        if (musicPlaying) {
          musicPlayer!.stop();
          musicPlaying = false;
        }
      } else if (state == AppLifecycleState.resumed) {
        if (!gameOver) {
          if (!musicPlaying) {
            musicPlaying = true;
            playMusic();
          }
        } else {
          if (!musicPlaying) {
            musicPlaying = true;
            playGameOver();
          }
        }
      }
    }
  }

  Widget showGameOver() {
    if (gameOver) {
      if (musicPlaying && musicPlayer != null) {
        musicPlayer!.stop();
        musicPlaying = false;
      }

      if (!musicPlaying) {
        musicPlaying = true;
        playGameOver();
      }

      return Stack(
        children: [
          Container(
            color: const Color(0xEE000000),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FancyButton(
                    child: Text(
                      "GAME OVER",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width(context) / 12,
                        fontFamily: 'Gameplay',
                      ),
                    ),
                    size: width(context) / 10,
                    color: const Color(0xFFCA3034),
                    onPressed: () {
                      Navigator.of(context)
                          .pushReplacement(InitRoute(Welcome()));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: FancyButton(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        child: Text(
                          "SHARE SCORE",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width(context) / 25,
                            fontFamily: 'Gameplay',
                          ),
                        ),
                      ),
                      size: width(context) / 20,
                      color: const Color(0xFF67AC5B),
                      onPressed: _share,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Material(
        child: Stack(
          children: [
            _gameEngine(context),
            showGameOver(),
          ],
        ),
      );
    });
  }
}
