#pragma once

#include <QObject>
#include <QTest>

class tst_HelloWorld : public QObject
{
    Q_OBJECT

private slots:
    void message_returnsHelloWorld();
    void formatMessage_returnsWrappedMessage();
    void message_isNotEmpty();
};
