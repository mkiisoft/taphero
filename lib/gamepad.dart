import 'dart:async';
import 'package:flutter/services.dart';

const GAMEPAD_BUTTON_UP = "UP";
const GAMEPAD_BUTTON_DOWN = "DOWN";

const GAMEPAD_DPAD_UP = "UP";
const GAMEPAD_DPAD_DOWN = "DOWN";
const GAMEPAD_DPAD_LEFT = "LEFT";
const GAMEPAD_DPAD_RIGHT = "RIGHT";

const GAMEPAD_BUTTON_A = "A";
const GAMEPAD_BUTTON_B = "B";
const GAMEPAD_BUTTON_X = "X";
const GAMEPAD_BUTTON_Y = "Y";
const GAMEPAD_BUTTON_Y_2 = "Y";

const GAMEPAD_BUTTON_L1 = "L1";
const GAMEPAD_BUTTON_L2 = "L2";

const GAMEPAD_BUTTON_R1 = "R1";
const GAMEPAD_BUTTON_R2 = "R2";

const GAMEPAD_BUTTON_START = "START";
const GAMEPAD_BUTTON_SELECT = "SELECT";

typedef void KeyListener(RawKeyEvent event);
typedef void GamePadListener(bool pressed, String key);

const ANDROID_MAPPING = {
  19: GAMEPAD_DPAD_UP,
  20: GAMEPAD_DPAD_DOWN,
  21: GAMEPAD_DPAD_LEFT,
  22: GAMEPAD_DPAD_RIGHT,
  96: GAMEPAD_BUTTON_A,
  97: GAMEPAD_BUTTON_B,
  99: GAMEPAD_BUTTON_X,
  100: GAMEPAD_BUTTON_Y,
  102: GAMEPAD_BUTTON_L1,
  103: GAMEPAD_BUTTON_R1,
  104: GAMEPAD_BUTTON_L2,
  105: GAMEPAD_BUTTON_R2,
  108: GAMEPAD_BUTTON_START,
  109: GAMEPAD_BUTTON_SELECT
};

const SWITCH_PRO_MAPPING = {
  19: GAMEPAD_DPAD_UP,
  20: GAMEPAD_DPAD_DOWN,
  21: GAMEPAD_DPAD_LEFT,
  22: GAMEPAD_DPAD_RIGHT,
  96: GAMEPAD_BUTTON_B,
  97: GAMEPAD_BUTTON_A,
  98: GAMEPAD_BUTTON_Y,
  99: GAMEPAD_BUTTON_X,
  102: GAMEPAD_BUTTON_L1,
  103: GAMEPAD_BUTTON_R1,
  104: GAMEPAD_BUTTON_L2,
  105: GAMEPAD_BUTTON_R2,
  108: GAMEPAD_BUTTON_START,
  109: GAMEPAD_BUTTON_SELECT
};

class GamePad {
  KeyListener listener;

  static const MethodChannel _channel = const MethodChannel('gamepad');

  static Future<bool> get isGamePadConnected async {
    final bool isConnected = await _channel.invokeMethod('isGamepadConnected');
    return isConnected;
  }

  static Future<String> get gamepadName async {
    final String name = await _channel.invokeMethod("getGamePadName");
    return name;
  }

  static Map<int, String> get switchMap => SWITCH_PRO_MAPPING;

  void setListener({GamePadListener gamePadListener, String name}) {
    listener = (RawKeyEvent e) {
      String evtType = e is RawKeyDownEvent ? GAMEPAD_BUTTON_DOWN : GAMEPAD_BUTTON_UP;

      if (e.data is RawKeyEventDataAndroid) {
        RawKeyEventDataAndroid androidEvent = e.data as RawKeyEventDataAndroid;

        String key = "";

        if (name == "Pro Controller") {
          key = SWITCH_PRO_MAPPING[androidEvent.keyCode];
        } else {
          key = ANDROID_MAPPING[androidEvent.keyCode];
        }

        if (key != null) {
          gamePadListener(evtType == "DOWN", key);
        }
      }
    };

    RawKeyboard.instance.addListener(listener);
  }

  void removeListener() {
    RawKeyboard.instance.removeListener(listener);
  }
}