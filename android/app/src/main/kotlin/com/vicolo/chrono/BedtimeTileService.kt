package com.vicolo.chrono

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class BedtimeTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        updateTile()
    }

    override fun onClick() {
        super.onClick()
        // Toggle bedtime routine via the MethodChannel
        // This runs in the tile service process, not the main activity,
        // so we use SharedPreferences to notify the app process
        val prefs = getSharedPreferences("com.vicolo.chrono", MODE_PRIVATE)
        // The app reads this flag and reacts; the widget data is also
        // refreshed when the next foreground task runs.
        prefs.edit().putBoolean("bedtime_tile_toggled", true).apply()
        updateTile()
    }

    private fun updateTile() {
        val tile = qsTile ?: return
        val prefs = getSharedPreferences("com.vicolo.chrono", MODE_PRIVATE)
        val enabled = prefs.getBoolean("bedtime_enabled", false)

        if (enabled) {
            tile.state = Tile.STATE_ACTIVE
            tile.label = "Bedtime: On"
        } else {
            tile.state = Tile.STATE_INACTIVE
            tile.label = "Bedtime: Off"
        }
        tile.updateTile()
    }
}
