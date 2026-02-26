#include "common/navigation/tst_navigation_controller.h"

#include <QSignalSpy>

void tst_NavigationController::initTestCase()
{
    nav = NavigationController::instance();
    QVERIFY(nav);
}

void tst_NavigationController::init()
{
    nav->push(QStringLiteral("__reset__"));
    nav->setCurrent(QString(), QVariantMap(), true, 0);
}

// --- initialState ---

void tst_NavigationController::initialState_currentUrlIsEmpty()
{
    QVERIFY(nav->currentUrl().isEmpty());
}

void tst_NavigationController::initialState_currentPropsAreEmpty()
{
    QCOMPARE(nav->currentProps(), QVariantMap());
}

void tst_NavigationController::initialState_showChromeIsTrue()
{
    QVERIFY(nav->currentShowChrome());
}

void tst_NavigationController::initialState_canGoBackIsFalse()
{
    QVERIFY(!nav->canGoBack());
}

void tst_NavigationController::initialState_canGoForwardIsFalse()
{
    QVERIFY(!nav->canGoForward());
}

void tst_NavigationController::initialState_historyLimitIsPositive()
{
    QVERIFY(nav->historyLimit() > 0);
}

// --- push ---

void tst_NavigationController::push_emitsPushRequested()
{
    QSignalSpy spy(nav, &NavigationController::pushRequested);
    nav->push(QStringLiteral("pages/Readme.qml"), {{"key", "value"}}, false);
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::push_signalContainsUrl()
{
    QSignalSpy spy(nav, &NavigationController::pushRequested);
    nav->push(QStringLiteral("pages/Readme.qml"), {{"key", "value"}}, false);
    QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("pages/Readme.qml"));
}

void tst_NavigationController::push_signalContainsProps()
{
    QVariantMap props{{"key", "value"}};
    QSignalSpy spy(nav, &NavigationController::pushRequested);
    nav->push(QStringLiteral("pages/Readme.qml"), props, false);
    QCOMPARE(spy.at(0).at(1).toMap(), props);
}

void tst_NavigationController::push_signalContainsShowChrome()
{
    QSignalSpy spy(nav, &NavigationController::pushRequested);
    nav->push(QStringLiteral("pages/Readme.qml"), {{"key", "value"}}, false);
    QCOMPARE(spy.at(0).at(2).toBool(), false);
}

void tst_NavigationController::push_clearsForwardStack()
{
    nav->setCurrent(QStringLiteral("page1"), QVariantMap(), true, 2);
    nav->pop();
    QVERIFY(nav->canGoForward());

    nav->push(QStringLiteral("page2"));
    QVERIFY(!nav->canGoForward());
}

void tst_NavigationController::push_clearingForwardStackEmitsCurrentChanged()
{
    nav->setCurrent(QStringLiteral("page1"), QVariantMap(), true, 2);
    nav->pop();

    QSignalSpy spy(nav, &NavigationController::currentChanged);
    nav->push(QStringLiteral("page2"));
    QVERIFY(spy.count() >= 1);
}

void tst_NavigationController::push_atHistoryLimitEmitsReplaceRequested()
{
    const int limit = nav->historyLimit();
    nav->setCurrent(QStringLiteral("deep"), QVariantMap(), true, limit);

    QSignalSpy spy(nav, &NavigationController::replaceRequested);
    nav->push(QStringLiteral("next"));
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::push_atHistoryLimitDoesNotEmitPushRequested()
{
    const int limit = nav->historyLimit();
    nav->setCurrent(QStringLiteral("deep"), QVariantMap(), true, limit);

    QSignalSpy spy(nav, &NavigationController::pushRequested);
    nav->push(QStringLiteral("next"));
    QCOMPARE(spy.count(), 0);
}

// --- setCurrent ---

void tst_NavigationController::setCurrent_emitsCurrentChanged()
{
    QSignalSpy spy(nav, &NavigationController::currentChanged);
    nav->setCurrent(QStringLiteral("pages/License.qml"), {{"id", 42}}, false, 2);
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::setCurrent_updatesCurrentUrl()
{
    nav->setCurrent(QStringLiteral("pages/License.qml"), {{"id", 42}}, false, 2);
    QCOMPARE(nav->currentUrl(), QStringLiteral("pages/License.qml"));
}

void tst_NavigationController::setCurrent_updatesCurrentProps()
{
    QVariantMap props{{"id", 42}};
    nav->setCurrent(QStringLiteral("pages/License.qml"), props, false, 2);
    QCOMPARE(nav->currentProps(), props);
}

void tst_NavigationController::setCurrent_updatesShowChrome()
{
    nav->setCurrent(QStringLiteral("pages/License.qml"), {{"id", 42}}, false, 2);
    QVERIFY(!nav->currentShowChrome());
}

void tst_NavigationController::setCurrent_updatesCanGoBack()
{
    nav->setCurrent(QStringLiteral("pages/License.qml"), {{"id", 42}}, false, 2);
    QVERIFY(nav->canGoBack());
}

void tst_NavigationController::setCurrent_identicalValuesEmitNoSignal()
{
    nav->setCurrent(QStringLiteral("page"), QVariantMap(), true, 1);

    QSignalSpy spy(nav, &NavigationController::currentChanged);
    nav->setCurrent(QStringLiteral("page"), QVariantMap(), true, 1);
    QCOMPARE(spy.count(), 0);
}

// --- pop ---

void tst_NavigationController::pop_atRootEmitsBackAtRoot()
{
    QSignalSpy spy(nav, &NavigationController::backAtRoot);
    nav->pop();
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::pop_atRootDoesNotEmitPopRequested()
{
    QSignalSpy spy(nav, &NavigationController::popRequested);
    nav->pop();
    QCOMPARE(spy.count(), 0);
}

void tst_NavigationController::pop_emitsPopRequested()
{
    nav->setCurrent(QStringLiteral("pages/Readme.qml"), QVariantMap(), true, 2);

    QSignalSpy spy(nav, &NavigationController::popRequested);
    nav->pop();
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::pop_enablesCanGoForward()
{
    nav->setCurrent(QStringLiteral("pages/Readme.qml"), QVariantMap(), true, 2);
    nav->pop();
    QVERIFY(nav->canGoForward());
}

// --- forward ---

void tst_NavigationController::forward_emptyStackIsNoOp()
{
    QSignalSpy spy(nav, &NavigationController::pushRequested);
    nav->forward();
    QCOMPARE(spy.count(), 0);
}

void tst_NavigationController::forward_emitsPushRequested()
{
    nav->setCurrent(QStringLiteral("pages/Readme.qml"), {{"key", "val"}}, false, 2);
    nav->pop();

    QSignalSpy spy(nav, &NavigationController::pushRequested);
    nav->forward();
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::forward_signalContainsSavedUrl()
{
    nav->setCurrent(QStringLiteral("pages/Readme.qml"), {{"key", "val"}}, false, 2);
    nav->pop();

    QSignalSpy spy(nav, &NavigationController::pushRequested);
    nav->forward();
    QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("pages/Readme.qml"));
}

void tst_NavigationController::forward_signalContainsSavedProps()
{
    QVariantMap props{{"key", "val"}};
    nav->setCurrent(QStringLiteral("pages/Readme.qml"), props, false, 2);
    nav->pop();

    QSignalSpy spy(nav, &NavigationController::pushRequested);
    nav->forward();
    QCOMPARE(spy.at(0).at(1).toMap(), props);
}

void tst_NavigationController::forward_signalContainsSavedShowChrome()
{
    nav->setCurrent(QStringLiteral("pages/Readme.qml"), {{"key", "val"}}, false, 2);
    nav->pop();

    QSignalSpy spy(nav, &NavigationController::pushRequested);
    nav->forward();
    QCOMPARE(spy.at(0).at(2).toBool(), false);
}

// --- replace ---

void tst_NavigationController::replace_emitsReplaceRequested()
{
    QSignalSpy spy(nav, &NavigationController::replaceRequested);
    nav->replace(QStringLiteral("pages/StyleShowcase.qml"), {{"mode", "edit"}}, false);
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::replace_signalContainsUrl()
{
    QSignalSpy spy(nav, &NavigationController::replaceRequested);
    nav->replace(QStringLiteral("pages/StyleShowcase.qml"), {{"mode", "edit"}}, false);
    QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("pages/StyleShowcase.qml"));
}

void tst_NavigationController::replace_signalContainsProps()
{
    QVariantMap props{{"mode", "edit"}};
    QSignalSpy spy(nav, &NavigationController::replaceRequested);
    nav->replace(QStringLiteral("pages/StyleShowcase.qml"), props, false);
    QCOMPARE(spy.at(0).at(1).toMap(), props);
}

void tst_NavigationController::replace_signalContainsShowChrome()
{
    QSignalSpy spy(nav, &NavigationController::replaceRequested);
    nav->replace(QStringLiteral("pages/StyleShowcase.qml"), {{"mode", "edit"}}, false);
    QCOMPARE(spy.at(0).at(2).toBool(), false);
}

void tst_NavigationController::replace_clearsForwardStack()
{
    nav->setCurrent(QStringLiteral("page1"), QVariantMap(), true, 2);
    nav->pop();
    QVERIFY(nav->canGoForward());

    nav->replace(QStringLiteral("page2"));
    QVERIFY(!nav->canGoForward());
}
