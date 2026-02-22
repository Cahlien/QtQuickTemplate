#include "platform_init.h"

#include <QCoreApplication>
#include <QJniObject>
#include <QQuickWindow>

void onFirstFrame(QQuickWindow *)
{
    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([]() {
        QJniObject activity = QJniObject::callStaticObjectMethod(
            "org/qtproject/qt/android/QtNative",
            "activity",
            "()Landroid/app/Activity;");

        if (activity.isValid()) {
            activity.callMethod<void>("onQtReady", "()V");
        } else {
            QJniObject::callStaticMethod<void>(
                "dev/crowell/qtquicktemplate/activities/MainActivity",
                "notifyQtReady",
                "()V");
        }
    });
}
