package com.marianozorilla.tap_hero

import android.annotation.TargetApi
import android.content.Context
import android.hardware.input.InputManager
import android.os.Build
import android.os.Bundle
import android.view.*

import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import android.view.InputDevice

class MainActivity: FlutterActivity(), InputManager.InputDeviceListener {

  private lateinit var inputManager: InputManager
  private lateinit var channel: MethodChannel

  @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    fixFocusGamepad()

    inputManager = getSystemService(Context.INPUT_SERVICE) as InputManager

    channel =  MethodChannel(flutterView, "gamepad")

    channel.setMethodCallHandler { call, result ->
      when {
          call.method == "isGamepadConnected" -> {
            val ids = InputDevice.getDeviceIds()
            for (id in ids) {
              val device = InputDevice.getDevice(id)
              val sources = device.sources

              if (sources and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD) {
                result.success(true)
              }
            }
            result.success(false)
          }
          call.method == "getGamePadName" -> {
            val gamepadIds = InputDevice.getDeviceIds()
            for (id in gamepadIds) {
              val device = InputDevice.getDevice(id)
              val sources = device.sources

              if (sources and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD) {
                result.success(device.name)
              }
            }
          }
          else -> result.notImplemented()
      }
    }
  }

  private fun fixFocusGamepad() {
    flutterView.isFocusable = false

    val root = findViewById<ViewGroup>(android.R.id.content)
    val addView = View(this)
    root.addView(addView)

    addView.layoutParams.height = 10
    addView.layoutParams.width = 10
    addView.requestLayout()

    addView.isFocusable = true
    addView.setOnKeyListener { _, keyCode, event ->
      val key = mutableMapOf<Int, Boolean>()
      key[keyCode] = event.action == KeyEvent.ACTION_DOWN
      channel.invokeMethod("keyCode", key)
      true
    }
  }

  override fun onResume() {
    super.onResume()
    inputManager.registerInputDeviceListener(this, null)
  }

  override fun onPause() {
    super.onPause()
    inputManager.unregisterInputDeviceListener(this)
  }

  override fun onInputDeviceRemoved(deviceId: Int) {
    channel.invokeMethod("gamepadRemoved", true, object: MethodChannel.Result {

      override fun success(p0: Any?) {
        println("ANDROID_CHANNEL: SUCCESS")
      }

      override fun error(p0: String?, p1: String?, p2: Any?) {
        println("ANDROID_CHANNEL: ERROR")
      }

      override fun notImplemented() {
        println("ANDROID_CHANNEL: NOT IMPLEMENTED")
      }
    })
  }

  override fun onInputDeviceAdded(deviceId: Int) {
    channel.invokeMethod("gamepadName", InputDevice.getDevice(deviceId).name, object: MethodChannel.Result {

      override fun success(p0: Any?) {
        println("ANDROID_CHANNEL: SUCCESS")
      }

      override fun error(p0: String?, p1: String?, p2: Any?) {
        println("ANDROID_CHANNEL: ERROR")
      }

      override fun notImplemented() {
        println("ANDROID_CHANNEL: NOT IMPLEMENTED")
      }
    })
  }

  override fun onInputDeviceChanged(deviceId: Int) {
    channel.invokeMethod("gamepadName", InputDevice.getDevice(deviceId).name, object: MethodChannel.Result {

      override fun success(p0: Any?) {
        println("ANDROID_CHANNEL: SUCCESS")
      }

      override fun error(p0: String?, p1: String?, p2: Any?) {
        println("ANDROID_CHANNEL: ERROR")
      }

      override fun notImplemented() {
        println("ANDROID_CHANNEL: NOT IMPLEMENTED")
      }
    })
  }
}
