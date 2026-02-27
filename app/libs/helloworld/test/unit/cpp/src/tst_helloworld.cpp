#include "tst_helloworld.h"

void tst_HelloWorld::message_returnsHelloWorld() const
{
    QCOMPARE(m_hw.message(), std::string_view("Hello World"));
}

void tst_HelloWorld::formatMessage_returnsWrappedMessage() const
{
    QCOMPARE(m_hw.formatMessage(), std::string("Message: 'Hello World'"));
}

void tst_HelloWorld::message_isNotEmpty() const
{
    QVERIFY(!m_hw.message().empty());
}
