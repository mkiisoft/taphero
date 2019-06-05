import 'dart:ui';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'particles.dart';
import 'route.dart';
import 'utils.dart';
import 'game.dart';
import 'gamepad.dart';
import 'button.dart';

class Welcome extends StatefulWidget {
  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with WidgetsBindingObserver, TickerProviderStateMixin {
  static AudioCache musicCache;
  static AudioPlayer instance;

  static var musicPlaying = false;

  static String skyAsset() => "assets/background/sky.png";

  static String logoAsset() => "assets/elements/taptaphero.png";

  static String heroAsset() => "assets/elements/hero.png";

  static String bossAsset() => "assets/elements/boss.png";

  var heroYAxis = 0.0;
  var bossYAxis = 1.0;

  AnimationController _controller;
  Animation _animationHero;
  Animation _animationBoss;

  var tapToPlay = false;
  var tapAlpha = 0.0;

  AnimationController _tapController;
  Animation _tapAnimation;

  AnimationController _fadeController;
  Animation _fadeAnimation;

  var fade = Colors.transparent;

  String _gamepadName = "";

  static var _gamepadXAxis = 250.0;

  static const MethodChannel _channel = const MethodChannel('gamepad');

  void initGame() {
    if (tapToPlay) _fadeController.forward();
  }

  void playMusic() async {
    musicCache = AudioCache(prefix: "audio/");
    instance = await musicCache.loop("welcome.mp3");
  }

  void initAnimation() {
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _animationHero = Tween(begin: 0.0, end: 0.6).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate))
      ..addStatusListener((state) {
        if (state == AnimationStatus.completed) {
          setState(() {
            tapToPlay = true;
          });
          _tapController.forward();
        }
      })
      ..addListener(() {
        setState(() {
          heroYAxis = _animationHero.value;
        });
      });

    _animationBoss = Tween(begin: 1.0, end: 0.6).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate))
      ..addListener(() {
        setState(() {
          bossYAxis = _animationBoss.value;
        });
      });

    _controller.forward();
  }

  void initTapAnimation() {
    _tapController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _tapAnimation =
        Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _tapController, curve: Curves.decelerate))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _tapController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              _tapController.forward();
            }
          })
          ..addListener(() {
            setState(() {
              tapAlpha = _tapAnimation.value;
            });
          });

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = ColorTween(begin: Colors.transparent, end: Colors.black)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.decelerate))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              Navigator.of(context).pushReplacement(InitRoute(Game()));
            }
          })
          ..addListener(() {
            fade = _fadeAnimation.value;
          });
  }

  void disposeAnimations() {
    _controller.dispose();
    _tapController.dispose();
    _fadeController.dispose();
  }

  @override
  void didChangeDependencies() {
    if (!Utils.isDesktop()) {
      if (!musicPlaying) {
        musicPlaying = true;
        playMusic();
      }
    }
    super.didChangeDependencies();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    initTapAnimation();
    initAnimation();

    GamePad.gamepadName.then((name) {
      setState(() {
        _gamepadName = name;
        _gamepadXAxis = 15.0;
        hideController();
      });
    });

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "gamepadName":
          setState(() {
            _gamepadName = call.arguments;
            _gamepadXAxis = 15.0;
            hideController();
          });
          break;
        case "gamepadRemoved":
          setState(() {
            _gamepadName = "Undefined";
            _gamepadXAxis = 250.0;
          });
          break;
        case "keyCode":
          var pair = Utils.mapToPair(Map<int, bool>.from(call.arguments));
          setState(() {
            if (pair.value) {
              switch(GamePad.switchMap[pair.key]) {
                case "A":
                  initGame();
                  break;
              }
            }
          });
          break;
      }
    });
  }
  
  void hideController() {
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _gamepadXAxis = 250.0;
      });
    });
  }

  @override
  void dispose() {
    disposeAnimations();

    if (!Utils.isDesktop()) {
      if (musicPlaying && instance != null) {
        instance.stop();
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
      final size = constraints.biggest.longestSide;
      return Stack(
        children: <Widget>[
          SizedBox.expand(
            child: Image.asset(
              skyAsset(),
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(child: Particles(30)),
          Align(
            alignment: Alignment.center,
            child: Align(
              alignment: Alignment(0.0, -1.0),
              heightFactor: bossYAxis,
              child: Image.asset(
                bossAsset(),
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 4.0,
              sigmaY: 4.0,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: heroYAxis,
                child: Image.asset(
                  heroAsset(),
                  width: size / 1.5,
                  height: size / 1.5,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Container(
              alignment: Alignment.topCenter,
              padding: EdgeInsets.only(top: constraints.maxHeight * 0.04, left: 15.0, right: 15.0),
              child: Image.asset(
                logoAsset(),
                height: 150.0,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: Opacity(
              opacity: tapAlpha,
              child: Container(
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.10),
                child: Image.asset(
                  "assets/elements/taptostart.png",
                  height: 55.0,
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: Duration(seconds: 2),
            child: GestureDetector(
              onTap: initGame,
              child: Container(
                color: fade,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: Curves.decelerate,
              transform: Matrix4.translationValues(_gamepadXAxis, -20, 0),
              child: FancyButton(
                size: 40,
                color: Color(0xFFEFF3ED),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      "assets/elements/controller.png",
                      fit: BoxFit.fill,
                      height: 20,
                      width: 45,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          _gamepadName,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: "Gameplay"
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      );
    });
  }
}
