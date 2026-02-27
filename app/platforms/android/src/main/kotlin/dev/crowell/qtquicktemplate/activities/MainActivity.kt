package dev.crowell.qtquicktemplate.activities

import android.annotation.SuppressLint
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import android.window.OnBackInvokedDispatcher
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import dev.crowell.qtquicktemplate.R
import dev.crowell.qtquicktemplate.extensions.dp
import org.qtproject.qt.android.bindings.QtActivity
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : QtActivity() {

    companion object {
        private const val TAG = "dev.crowell.qtquicktemplate.activities.MainActivity"
        private val ready = AtomicBoolean(false)

        @JvmStatic
        fun notifyQtReady() {
            ready.set(true)
        }
    }

    external fun nativeBackRequested()

    private var overlay: View? = null
    private var versionView: TextView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.i(TAG, "MainActivity.onCreate")
        val splash = installSplashScreen()
        splash.setKeepOnScreenCondition { false }

        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT
            ) {
                nativeBackRequested()
            }
        }

        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = 0x00000000
        window.navigationBarColor = 0x00000000

        val controller = WindowCompat.getInsetsController(window, window.decorView)
        controller.isAppearanceLightStatusBars = false
        controller.isAppearanceLightNavigationBars = false

        val root = layoutInflater.inflate(R.layout.splash_screen, null)
        overlay = root
        versionView = root.findViewById(R.id.splash_text)

        addContentView(
            root,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        )

        val pkgMgr = packageManager
        val versionName = try {
            pkgMgr.getPackageInfo(packageName, 0).versionName
        } catch (e: Exception) {
            getString(R.string.version_unknown)
        }
        versionView?.text = getString(R.string.version_label, versionName)

        ViewCompat.setOnApplyWindowInsetsListener(root) { v, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars())

            v.setPadding(v.paddingLeft, bars.top, v.paddingRight, bars.bottom)
            val footer = versionView
            if (footer != null) {
                val lp = footer.layoutParams as ViewGroup.MarginLayoutParams
                lp.bottomMargin = 30.dp + bars.bottom
                footer.layoutParams = lp
            }
            insets
        }

        Log.i(TAG, "MainActivity.onCreate complete")
    }

    override fun onResume() {
        super.onResume()
        dismissOverlay()
    }

    private fun dismissOverlay() {
        if (!ready.get()) return
        val v = overlay ?: return
        Log.d(TAG, "Dismissing splash overlay")
        v.animate()
            .alpha(0f)
            .setDuration(220L)
            .withEndAction {
                val parent = v.parent as? ViewGroup
                parent?.removeView(v)
                overlay = null
            }
            .start()
    }

    fun onQtReady() {
        Log.d(TAG, "onQtReady")
        notifyQtReady()
        runOnUiThread { dismissOverlay() }
    }

    @Suppress("DEPRECATION")
    @SuppressLint("MissingSuperCall")
    override fun onBackPressed() {
        if (Build.VERSION.SDK_INT < 33) {
            nativeBackRequested()
        }
    }
}
