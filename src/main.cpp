#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QQuickStyle::setStyle("AppStyle");
    QQuickStyle::setFallbackStyle("Basic");

    QGuiApplication app(argc, argv);
    app.setApplicationName("QtQuickTemplate");
    app.setApplicationVersion(APP_VERSION_STRING);
    app.setOrganizationName("YourOrganization");

    QQmlApplicationEngine engine;

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("QtQuickTemplate", "Main");

    return app.exec();
}
