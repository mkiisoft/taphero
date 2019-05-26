import 'package:flutter/material.dart';

import 'game.dart';

class InitGameRoute extends PageRoute {

  @override
  Color get barrierColor => Colors.black;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration(milliseconds: 500);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return FadeTransition(opacity: animation, child: Game());
  }
}