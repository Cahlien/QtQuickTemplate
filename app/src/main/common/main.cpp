#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <memory>

#include "helloworld.h"

#if defined(QTQUICKTEMPLATE_USE_HELLOWORLD_MODULE)
import helloworld;
#else
#include <helloworld.h>
#endif

#include "platform_init.h"

int main(int argc, char *argv[])
{
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");

#ifdef Q_OS_LINUX
    qputenv("QT_QPA_PLATFORMTHEME", "generic");
#endif

    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("dev.crowell.AppStyle");
    QQuickStyle::setFallbackStyle("Basic");

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

    const dev::crowell::helloworld::HelloWorld helloWorld{};

    qDebug() << helloWorld.formatMessage();

    engine.loadFromModule("dev.crowell.QtQuickTemplate", "Main");

    return app.exec();
}
