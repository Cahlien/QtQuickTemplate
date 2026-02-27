#pragma once

#include <helloworld.h>
#include <QObject>
#include <QTest>

class tst_HelloWorld : public QObject
{
    Q_OBJECT

private slots:
    void message_returnsHelloWorld() const;
    void formatMessage_returnsWrappedMessage() const;
    void message_isNotEmpty() const;

private:
    const HelloWorld m_hw{};
};
