import 'package:flutter/material.dart';
import 'powerups.dart';
import 'bosses.dart';

class Utils {
  
  static List<PowerUps> getPowerUps() {
    var list = List<PowerUps>();
    list.add(PowerUps("Master Sword", 2.15, false, 50));
    list.add(PowerUps("Lengendary Sword", 2.45, false, 180));
    list.add(PowerUps("Keyblade", 3.75, false, 300));
    list.add(PowerUps("Lightsaber", 4.95, false, 520));
    list.add(PowerUps("Buster Sword", 6.15, false, 1700));
    list.add(PowerUps("Soul Edge", 8.65, false, 2400));
    return list;
  }
  
  static List<Bosses> getBosses() {
    var list = List<Bosses>();
    list.add(Bosses("Lunabi", 450, "assets/boss/boss_one.png"));
    list.add(Bosses("ivygrass", 880, "assets/boss/boss_two.png"));
    list.add(Bosses("Tombster", 1120, "assets/boss/boss_three.png"));
    list.add(Bosses("Glidestone", 2260, "assets/boss/boss_four.png"));
    list.add(Bosses("Smocka", 2900, "assets/boss/boss_five.png"));
    list.add(Bosses("Clowntorch", 4100, "assets/boss/boss_six.png"));
    list.add(Bosses("Marsattack", 5380, "assets/boss/boss_seven.png"));
    list.add(Bosses("Unknown", 7000, "assets/boss/boss_eight.png"));
    list.add(Bosses("ExArthur", 10000, "assets/boss/boss_nine.png"));
    return list;
  }

  static TextStyle textStyle(double size, {Color color = Colors.white}) {
    return TextStyle(
      color: color,
      fontFamily: "Gameplay",
      fontSize: size,
    );
  }
}

class StrokeText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;
  final String fontFamily;

  const StrokeText(
      this.text, {
        Key key,
        this.fontSize,
        this.fontWeight,
        this.color,
        this.strokeColor,
        this.strokeWidth,
        this.fontFamily
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            color: color,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            foreground: Paint()
              ..strokeWidth = strokeWidth
              ..color = strokeColor
              ..style = PaintingStyle.stroke,
          ),
        ),
      ],
    );
  }
}