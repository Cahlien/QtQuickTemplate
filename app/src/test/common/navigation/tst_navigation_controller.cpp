#include <QSignalSpy>
#include <QTest>

#include "navigation/navigation_controller.h"

using NavigationController = dev::crowell::qtquicktemplate::navigation::NavigationController;

class tst_NavigationController : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase()
    {
        nav = NavigationController::instance();
        QVERIFY(nav);
    }

    void init()
    {
        nav->push(QStringLiteral("__reset__"));
        nav->setCurrent(QString(), QVariantMap(), true, 0);
    }

    void initialState()
    {
        QVERIFY(nav->currentUrl().isEmpty());
        QCOMPARE(nav->currentProps(), QVariantMap());
        QVERIFY(nav->currentShowChrome());
        QVERIFY(!nav->canGoBack());
        QVERIFY(!nav->canGoForward());
        QVERIFY(nav->historyLimit() > 0);
    }

    void pushEmitsPushRequested()
    {
        QSignalSpy spy(nav, &NavigationController::pushRequested);
        QVariantMap props{{"key", "value"}};

        nav->push(QStringLiteral("pages/Readme.qml"), props, false);

        QCOMPARE(spy.count(), 1);
        QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("pages/Readme.qml"));
        QCOMPARE(spy.at(0).at(1).toMap(), props);
        QCOMPARE(spy.at(0).at(2).toBool(), false);
    }

    void setCurrentUpdatesProperties()
    {
        QSignalSpy spy(nav, &NavigationController::currentChanged);
        QVariantMap props{{"id", 42}};

        nav->setCurrent(QStringLiteral("pages/License.qml"), props, false, 2);

        QCOMPARE(spy.count(), 1);
        QCOMPARE(nav->currentUrl(), QStringLiteral("pages/License.qml"));
        QCOMPARE(nav->currentProps(), props);
        QVERIFY(!nav->currentShowChrome());
        QVERIFY(nav->canGoBack());
    }

    void setCurrentNoChangeNoSignal()
    {
        nav->setCurrent(QStringLiteral("page"), QVariantMap(), true, 1);

        QSignalSpy spy(nav, &NavigationController::currentChanged);
        nav->setCurrent(QStringLiteral("page"), QVariantMap(), true, 1);

        QCOMPARE(spy.count(), 0);
    }

    void popAtRootEmitsBackAtRoot()
    {
        QSignalSpy backSpy(nav, &NavigationController::backAtRoot);
        QSignalSpy popSpy(nav, &NavigationController::popRequested);

        nav->pop();

        QCOMPARE(backSpy.count(), 1);
        QCOMPARE(popSpy.count(), 0);
    }

    void popSavesToForwardStack()
    {
        nav->setCurrent(QStringLiteral("pages/Readme.qml"), QVariantMap(), true, 2);
        QVERIFY(nav->canGoBack());
        QVERIFY(!nav->canGoForward());

        QSignalSpy spy(nav, &NavigationController::popRequested);
        nav->pop();

        QCOMPARE(spy.count(), 1);
        QVERIFY(nav->canGoForward());
    }

    void forwardEmptyIsNoOp()
    {
        QSignalSpy spy(nav, &NavigationController::pushRequested);

        nav->forward();

        QCOMPARE(spy.count(), 0);
    }

    void forwardEmitsPushRequestedWithSavedEntry()
    {
        QVariantMap props{{"key", "val"}};
        nav->setCurrent(QStringLiteral("pages/Readme.qml"), props, false, 2);
        nav->pop();

        QSignalSpy spy(nav, &NavigationController::pushRequested);
        nav->forward();

        QCOMPARE(spy.count(), 1);
        QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("pages/Readme.qml"));
        QCOMPARE(spy.at(0).at(1).toMap(), props);
        QCOMPARE(spy.at(0).at(2).toBool(), false);
    }

    void pushClearsForwardStack()
    {
        nav->setCurrent(QStringLiteral("page1"), QVariantMap(), true, 2);
        nav->pop();
        QVERIFY(nav->canGoForward());

        QSignalSpy changedSpy(nav, &NavigationController::currentChanged);
        nav->push(QStringLiteral("page2"));

        QVERIFY(!nav->canGoForward());
        QVERIFY(changedSpy.count() >= 1);
    }

    void replaceEmitsReplaceRequested()
    {
        QSignalSpy spy(nav, &NavigationController::replaceRequested);
        QVariantMap props{{"mode", "edit"}};

        nav->replace(QStringLiteral("pages/StyleShowcase.qml"), props, false);

        QCOMPARE(spy.count(), 1);
        QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("pages/StyleShowcase.qml"));
        QCOMPARE(spy.at(0).at(1).toMap(), props);
        QCOMPARE(spy.at(0).at(2).toBool(), false);
    }

    void replaceClearsForwardStack()
    {
        nav->setCurrent(QStringLiteral("page1"), QVariantMap(), true, 2);
        nav->pop();
        QVERIFY(nav->canGoForward());

        nav->replace(QStringLiteral("page2"));

        QVERIFY(!nav->canGoForward());
    }

    void historyLimitCapsStack()
    {
        const int limit = nav->historyLimit();
        nav->setCurrent(QStringLiteral("deep"), QVariantMap(), true, limit);

        QSignalSpy replaceSpy(nav, &NavigationController::replaceRequested);
        QSignalSpy pushSpy(nav, &NavigationController::pushRequested);

        nav->push(QStringLiteral("next"));

        QCOMPARE(replaceSpy.count(), 1);
        QCOMPARE(pushSpy.count(), 0);
    }

private:
    NavigationController *nav{};
};

QTEST_GUILESS_MAIN(tst_NavigationController)
#include "tst_navigation_controller.moc"
