#include <QCoreApplication>
#include <QTest>

#include "helloworld/tst_helloworld.h"
#include "common/navigation/tst_navigation_controller.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    int status = 0;

    tst_HelloWorld hw;
    status |= QTest::qExec(&hw, argc, argv);

    tst_NavigationController nc;
    status |= QTest::qExec(&nc, argc, argv);

    return status;
}
