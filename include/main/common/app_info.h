#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

namespace dev::crowell::qtquicktemplate {

class AppInfo : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString version READ version CONSTANT)

public:
    explicit AppInfo(QObject *parent = nullptr) : QObject(parent) {}

    QString version() const;
};

} // namespace dev::crowell::qtquicktemplate
