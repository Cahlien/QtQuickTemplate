#include "common/navigation/tst_navigation_controller.h"

#include <QSignalSpy>

void tst_NavigationController::initTestCase()
{
    nav = NavigationController::instance();
    QVERIFY(nav);
}

void tst_NavigationController::init() const
{
    nav->push(QStringLiteral("__reset__"));
    nav->setCurrent(QString(), QVariantMap(), true, 0);
}

void tst_NavigationController::initialState_currentUrlIsEmpty() const
{
    QVERIFY(nav->currentUrl().isEmpty());
}

void tst_NavigationController::initialState_currentPropsAreEmpty() const
{
    QCOMPARE(nav->currentProps(), QVariantMap());
}

void tst_NavigationController::initialState_showChromeIsTrue() const
{
    QVERIFY(nav->currentShowChrome());
}

void tst_NavigationController::initialState_canGoBackIsFalse() const
{
    QVERIFY(!nav->canGoBack());
}

void tst_NavigationController::initialState_canGoForwardIsFalse() const
{
    QVERIFY(!nav->canGoForward());
}

void tst_NavigationController::initialState_historyLimitIsPositive() const
{
    QVERIFY(nav->historyLimit() > 0);
}

void tst_NavigationController::push_emitsPushRequested() const
{
    QSignalSpy spy{nav, &NavigationController::pushRequested};
    nav->push(QStringLiteral("pages/Readme.qml"), {{"key", "value"}}, false);
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::push_signalContainsUrl() const
{
    QSignalSpy spy{nav, &NavigationController::pushRequested};
    nav->push(QStringLiteral("pages/Readme.qml"), {{"key", "value"}}, false);
    QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("pages/Readme.qml"));
}

void tst_NavigationController::push_signalContainsProps() const
{
    const QVariantMap props{{"key", "value"}};
    QSignalSpy spy{nav, &NavigationController::pushRequested};
    nav->push(QStringLiteral("pages/Readme.qml"), props, false);
    QCOMPARE(spy.at(0).at(1).toMap(), props);
}

void tst_NavigationController::push_signalContainsShowChrome() const
{
    QSignalSpy spy{nav, &NavigationController::pushRequested};
    nav->push(QStringLiteral("pages/Readme.qml"), {{"key", "value"}}, false);
    QCOMPARE(spy.at(0).at(2).toBool(), false);
}

void tst_NavigationController::push_clearsForwardStack() const
{
    nav->setCurrent(QStringLiteral("page1"), QVariantMap(), true, 2);
    nav->pop();
    QVERIFY(nav->canGoForward());

    nav->push(QStringLiteral("page2"));
    QVERIFY(!nav->canGoForward());
}

void tst_NavigationController::push_clearingForwardStackEmitsCurrentChanged() const
{
    nav->setCurrent(QStringLiteral("page1"), QVariantMap(), true, 2);
    nav->pop();

    QSignalSpy spy{nav, &NavigationController::currentChanged};
    nav->push(QStringLiteral("page2"));
    QVERIFY(spy.count() >= 1);
}

void tst_NavigationController::push_atHistoryLimitEmitsReplaceRequested() const
{
    const int limit{nav->historyLimit()};
    nav->setCurrent(QStringLiteral("deep"), QVariantMap(), true, limit);

    QSignalSpy spy{nav, &NavigationController::replaceRequested};
    nav->push(QStringLiteral("next"));
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::push_atHistoryLimitDoesNotEmitPushRequested() const
{
    const int limit{nav->historyLimit()};
    nav->setCurrent(QStringLiteral("deep"), QVariantMap(), true, limit);

    QSignalSpy spy{nav, &NavigationController::pushRequested};
    nav->push(QStringLiteral("next"));
    QCOMPARE(spy.count(), 0);
}

void tst_NavigationController::setCurrent_emitsCurrentChanged() const
{
    QSignalSpy spy{nav, &NavigationController::currentChanged};
    nav->setCurrent(QStringLiteral("pages/License.qml"), {{"id", 42}}, false, 2);
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::setCurrent_updatesCurrentUrl() const
{
    nav->setCurrent(QStringLiteral("pages/License.qml"), {{"id", 42}}, false, 2);
    QCOMPARE(nav->currentUrl(), QStringLiteral("pages/License.qml"));
}

void tst_NavigationController::setCurrent_updatesCurrentProps() const
{
    const QVariantMap props{{"id", 42}};
    nav->setCurrent(QStringLiteral("pages/License.qml"), props, false, 2);
    QCOMPARE(nav->currentProps(), props);
}

void tst_NavigationController::setCurrent_updatesShowChrome() const
{
    nav->setCurrent(QStringLiteral("pages/License.qml"), {{"id", 42}}, false, 2);
    QVERIFY(!nav->currentShowChrome());
}

void tst_NavigationController::setCurrent_updatesCanGoBack() const
{
    nav->setCurrent(QStringLiteral("pages/License.qml"), {{"id", 42}}, false, 2);
    QVERIFY(nav->canGoBack());
}

void tst_NavigationController::setCurrent_identicalValuesEmitNoSignal() const
{
    nav->setCurrent(QStringLiteral("page"), QVariantMap(), true, 1);

    QSignalSpy spy{nav, &NavigationController::currentChanged};
    nav->setCurrent(QStringLiteral("page"), QVariantMap(), true, 1);
    QCOMPARE(spy.count(), 0);
}

void tst_NavigationController::pop_atRootEmitsBackAtRoot() const
{
    QSignalSpy spy{nav, &NavigationController::backAtRoot};
    nav->pop();
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::pop_atRootDoesNotEmitPopRequested() const
{
    QSignalSpy spy{nav, &NavigationController::popRequested};
    nav->pop();
    QCOMPARE(spy.count(), 0);
}

void tst_NavigationController::pop_emitsPopRequested() const
{
    nav->setCurrent(QStringLiteral("pages/Readme.qml"), QVariantMap(), true, 2);

    QSignalSpy spy{nav, &NavigationController::popRequested};
    nav->pop();
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::pop_enablesCanGoForward() const
{
    nav->setCurrent(QStringLiteral("pages/Readme.qml"), QVariantMap(), true, 2);
    nav->pop();
    QVERIFY(nav->canGoForward());
}

void tst_NavigationController::forward_emptyStackIsNoOp() const
{
    QSignalSpy spy{nav, &NavigationController::pushRequested};
    nav->forward();
    QCOMPARE(spy.count(), 0);
}

void tst_NavigationController::forward_emitsPushRequested() const
{
    nav->setCurrent(QStringLiteral("pages/Readme.qml"), {{"key", "val"}}, false, 2);
    nav->pop();

    QSignalSpy spy{nav, &NavigationController::pushRequested};
    nav->forward();
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::forward_signalContainsSavedUrl() const
{
    nav->setCurrent(QStringLiteral("pages/Readme.qml"), {{"key", "val"}}, false, 2);
    nav->pop();

    QSignalSpy spy{nav, &NavigationController::pushRequested};
    nav->forward();
    QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("pages/Readme.qml"));
}

void tst_NavigationController::forward_signalContainsSavedProps() const
{
    const QVariantMap props{{"key", "val"}};
    nav->setCurrent(QStringLiteral("pages/Readme.qml"), props, false, 2);
    nav->pop();

    QSignalSpy spy{nav, &NavigationController::pushRequested};
    nav->forward();
    QCOMPARE(spy.at(0).at(1).toMap(), props);
}

void tst_NavigationController::forward_signalContainsSavedShowChrome() const
{
    nav->setCurrent(QStringLiteral("pages/Readme.qml"), {{"key", "val"}}, false, 2);
    nav->pop();

    QSignalSpy spy{nav, &NavigationController::pushRequested};
    nav->forward();
    QCOMPARE(spy.at(0).at(2).toBool(), false);
}

void tst_NavigationController::replace_emitsReplaceRequested() const
{
    QSignalSpy spy{nav, &NavigationController::replaceRequested};
    nav->replace(QStringLiteral("pages/StyleShowcase.qml"), {{"mode", "edit"}}, false);
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::replace_signalContainsUrl() const
{
    QSignalSpy spy{nav, &NavigationController::replaceRequested};
    nav->replace(QStringLiteral("pages/StyleShowcase.qml"), {{"mode", "edit"}}, false);
    QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("pages/StyleShowcase.qml"));
}

void tst_NavigationController::replace_signalContainsProps() const
{
    const QVariantMap props{{"mode", "edit"}};
    QSignalSpy spy{nav, &NavigationController::replaceRequested};
    nav->replace(QStringLiteral("pages/StyleShowcase.qml"), props, false);
    QCOMPARE(spy.at(0).at(1).toMap(), props);
}

void tst_NavigationController::replace_signalContainsShowChrome() const
{
    QSignalSpy spy{nav, &NavigationController::replaceRequested};
    nav->replace(QStringLiteral("pages/StyleShowcase.qml"), {{"mode", "edit"}}, false);
    QCOMPARE(spy.at(0).at(2).toBool(), false);
}

void tst_NavigationController::replace_clearsForwardStack() const
{
    nav->setCurrent(QStringLiteral("page1"), QVariantMap(), true, 2);
    nav->pop();
    QVERIFY(nav->canGoForward());

    nav->replace(QStringLiteral("page2"));
    QVERIFY(!nav->canGoForward());
}
