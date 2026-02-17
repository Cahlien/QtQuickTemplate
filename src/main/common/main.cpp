#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>

import helloworld;

#include "platform_init.h"

int main(int argc, char *argv[])
{
    QQuickStyle::setStyle("dev.crowell.AppStyle");
    QQuickStyle::setFallbackStyle("Basic");

    QGuiApplication app(argc, argv);
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

            if (!obj) {
                QCoreApplication::exit(-1);
                return;
            }

            auto *window = qobject_cast<QQuickWindow *>(obj);
            if (window) {
                QObject::connect(window, &QQuickWindow::frameSwapped, window, [=]() {
                    onFirstFrame(window);
                    QObject::disconnect(window, nullptr, nullptr, nullptr);
                });
            }
        },
        Qt::QueuedConnection
    );

    HelloWorld helloWorld{};

    // Demonstrating successful use of the HelloWorld class from the helloworld module
    qDebug() << helloWorld.formatMessage();

    engine.loadFromModule("dev.crowell.QtQuickTemplate", "Main");

    return app.exec();
}
