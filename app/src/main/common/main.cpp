#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <memory>

#if defined(QTQUICKTEMPLATE_USE_HELLOWORLD_MODULE)
import helloworld;
#else
#include <helloworld.h>
#endif

#include "platform_init.h"

int main(int argc, char *argv[])
{
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");

    // Prevent the desktop platform theme (e.g. KDE's KDEPlatformTheme) from
    // overriding our custom Qt Quick Controls style with Breeze/org.kde.desktop.
    // The KDE platform plugin programmatically forces its style AFTER both
    // QT_QUICK_CONTROLS_STYLE and QQuickStyle::setStyle() are evaluated,
    // so the only reliable way to use a custom style on KDE is to opt out of
    // the platform theme entirely.  This must happen before QGuiApplication.
    qputenv("QT_QPA_PLATFORMTHEME", "generic");

    QQuickStyle::setStyle("dev.crowell.AppStyle");
    QQuickStyle::setFallbackStyle("Basic");

    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/qt/qml/dev/crowell/QtQuickTemplate/app_icon.png"));
    app.setApplicationName("QtQuickTemplate");
    app.setApplicationVersion(APP_VERSION_STRING);
    app.setOrganizationName("YourOrganization");

    QQmlApplicationEngine engine;

    const QUrl mainUrl(QStringLiteral("qrc:/qt/qml/dev/crowell/QtQuickTemplate/Main.qml"));

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [mainUrl](QObject *obj, const QUrl &objUrl) {
            if (objUrl != mainUrl)
                return;

            if (!obj)
            {
                QCoreApplication::exit(-1);
                return;
            }

            auto *window = qobject_cast<QQuickWindow *>(obj);
            if (window)
            {
                QObject::connect(
                    window,
                    &QQuickWindow::frameSwapped,
                    window, [window]() {
                        dev::crowell::qtquicktemplate::platform::onFirstFrame(window);
                    },
                    Qt::SingleShotConnection
                );
            }
        },
        Qt::QueuedConnection
    );

    const HelloWorld helloWorld{};

    qDebug() << helloWorld.formatMessage();

    engine.loadFromModule("dev.crowell.QtQuickTemplate", "Main");

    return app.exec();
}
