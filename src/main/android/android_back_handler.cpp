// android_back_handler.cpp
//
// JNI entry-point called by Kotlin's OnBackInvokedCallback on the Android UI
// thread (Android 13+ / API 33+).  The symbol name MUST match the Kotlin
// external declaration exactly:
//
//   package dev.crowell.app.template.activities
//   class   MainActivity
//   method  nativeBackRequested()
//
// → Java_dev_crowell_app_template_activities_MainActivity_nativeBackRequested

#include "navigation_controller.h"

#include <QCoreApplication>  // pulls in qcoreapplication_platform.h → QNativeInterface::QAndroidApplication
#include <QDebug>
#include <QJniObject>
#include <QMetaObject>
#include <jni.h>

// ── JNI back-gesture entry-point ──────────────────────────────────────────────

extern "C" {

JNIEXPORT void JNICALL
Java_dev_crowell_app_template_activities_MainActivity_nativeBackRequested(
    JNIEnv * /*env*/, jobject /*thiz*/)
{
    qDebug() << "JNI: nativeBackRequested fired";
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

// ── Platform implementation of NavigationController::minimizeApp() ────────────
//
// This file is compiled only for Android (see CMakeLists.txt target_sources).
// platform_init_default.cpp provides the no-op for all other platforms.

void NavigationController::minimizeApp()
{
    // Move the task to the background rather than finishing the Activity.
    // Must be called on the Android UI thread — runOnAndroidMainThread ensures
    // correct dispatch regardless of which thread QML calls us from.
    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([]() {
        QJniObject activity = QJniObject::callStaticObjectMethod(
            "org/qtproject/qt/android/QtNative",
            "activity",
            "()Landroid/app/Activity;");

        if (activity.isValid())
            activity.callMethod<jboolean>("moveTaskToBack", "(Z)Z", true);
    });
}
