#include "helloworld/tst_helloworld.h"

#include "helloworld.h"

void tst_HelloWorld::message_returnsHelloWorld()
{
    HelloWorld hw;
    QCOMPARE(hw.message(), std::string_view("Hello World"));
}

void tst_HelloWorld::formatMessage_returnsWrappedMessage()
{
    HelloWorld hw;
    QCOMPARE(hw.formatMessage(), std::string("Message: 'Hello World'"));
}

void tst_HelloWorld::message_isNotEmpty()
{
    HelloWorld hw;
    QVERIFY(!hw.message().empty());
}
