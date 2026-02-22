// android_back_handler.cpp
//
// JNI entry-point called by Kotlin's OnBackInvokedCallback on the Android UI
// thread (Android 13+ / API 33+).  The symbol name MUST match the Kotlin
// external declaration exactly:
//
//   package dev.crowell.qtquicktemplate.activities
//   class   MainActivity
//   method  nativeBackRequested()
//
// → Java_dev_crowell_qtquicktemplate_activities_MainActivity_nativeBackRequested

#include "navigation/navigation_controller.h"

#include <QMetaObject>
#include <jni.h>

// ── JNI back-gesture entry-point ──────────────────────────────────────────────

using dev::crowell::qtquicktemplate::navigation::NavigationController;

extern "C" {

JNIEXPORT void JNICALL
Java_dev_crowell_qtquicktemplate_activities_MainActivity_nativeBackRequested(
    JNIEnv * /*env*/, jobject /*thiz*/)
{
    // We are on the Android UI thread here.  NavigationController::pop()
    // emits signals that drive QML/StackView mutations, which must happen on
    // the Qt main thread.  Qt::QueuedConnection posts an event across threads
    // safely without blocking the UI thread.
    QMetaObject::invokeMethod(
        NavigationController::instance(),
        "pop",
        Qt::QueuedConnection);
}

} // extern "C"
