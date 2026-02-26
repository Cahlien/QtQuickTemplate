#include <QTest>

#include "helloworld.h"

class tst_HelloWorld : public QObject
{
    Q_OBJECT

private slots:
    void messageContent()
    {
        HelloWorld hw;
        QCOMPARE(hw.message(), std::string_view("Hello World"));
    }

    void formatMessageOutput()
    {
        HelloWorld hw;
        QCOMPARE(hw.formatMessage(), std::string("Message: 'Hello World'"));
    }

    void messageIsNotEmpty()
    {
        HelloWorld hw;
        QVERIFY(!hw.message().empty());
    }
};

QTEST_APPLESS_MAIN(tst_HelloWorld)
#include "tst_helloworld.moc"
