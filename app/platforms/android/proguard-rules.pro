# Qt JNI bindings — referenced from native code via FindClass/GetMethodID
-keep class org.qtproject.qt.android.** { *; }
-keep class org.qtproject.qt.android.bindings.** { *; }

# App classes called from JNI (nativeBackRequested, onQtReady, notifyQtReady)
-keep class dev.crowell.qtquicktemplate.activities.MainActivity {
    native <methods>;
    public static void notifyQtReady();
    public void onQtReady();
}

# AndroidX SplashScreen
-keep class androidx.core.splashscreen.** { *; }
