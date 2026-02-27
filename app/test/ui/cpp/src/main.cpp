#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

#include <Spix/QtQmlBot.h>

#include "tst_navigation_ui.h"

int main(int argc, char *argv[])
{
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");
    qputenv("QT_QPA_PLATFORMTHEME", "generic");

    QQuickStyle::setStyle("dev.crowell.AppStyle");
    QQuickStyle::setFallbackStyle("Basic");

    QGuiApplication app(argc, argv);
    app.setApplicationName("QtQuickTemplate");
    app.setOrganizationName("YourOrganization");

    QQmlApplicationEngine engine;
    engine.loadFromModule("dev.crowell.QtQuickTemplate", "Main");

    tst_NavigationUI testServer;
    spix::QtQmlBot bot;
    bot.runTestServer(testServer);

    const int appResult = app.exec();
    return appResult == 0 && testServer.passed() ? 0 : 1;
}
