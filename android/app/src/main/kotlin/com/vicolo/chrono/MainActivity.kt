package com.vicolo.chrono

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.ArrayList
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant;

class MainActivity: FlutterActivity() {
    private val CHANNEL_ALARM = "com.vicolo.chrono/alarm"
    private val CHANNEL_BEDTIME = "com.vicolo.chrono/bedtime"
    private lateinit var dndController: DndController

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        dndController = DndController(this)

        MethodChannel(flutterEngine.dartExecutor, CHANNEL_BEDTIME).setMethodCallHandler(
            object : MethodCallHandler {
                override fun onMethodCall(call: MethodCall, result: Result) {
                    when (call.method) {
                        "isDndAllowed" -> {
                            result.success(dndController.isDndAllowed())
                        }
                        "requestDndAccess" -> {
                            dndController.requestDndAccess()
                            result.success(null)
                        }
                        "setDnd" -> {
                            val enabled = call.argument<Boolean>("enabled") ?: return
                            dndController.setDnd(enabled)
                            result.success(null)
                        }
                        "getCurrentDndMode" -> {
                            result.success(dndController.getCurrentDndMode())
                        }
                        else -> {
                            result.notImplemented()
                        }
                    }
                }
            }
        )
    }
}
