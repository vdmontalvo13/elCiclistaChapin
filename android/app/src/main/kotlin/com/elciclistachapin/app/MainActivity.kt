package com.elciclistachapin.app

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // En Android 12+ el sistema muestra un splash nativo automático con el
        // ícono de la app. Lo descartamos de inmediato para que solo se vea el
        // SplashScreen de Flutter.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                splashScreenView.remove()
            }
        }
        super.onCreate(savedInstanceState)
    }
}
