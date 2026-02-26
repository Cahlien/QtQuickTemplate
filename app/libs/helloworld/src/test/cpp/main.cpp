#include <QCoreApplication>
#include <QTest>

#include "helloworld/tst_helloworld.h"

int main(int argc, char *argv[])
{
    QCoreApplication app{argc, argv};

    int status{0};

    tst_HelloWorld hw{};
    status |= QTest::qExec(&hw, argc, argv);

    return status;
}
