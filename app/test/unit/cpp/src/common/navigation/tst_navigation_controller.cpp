#include "common/navigation/tst_navigation_controller.h"

#include <QSignalSpy>

void tst_NavigationController::init()
{
    m_nav.resetForTesting();
}

void tst_NavigationController::initialState_currentUrlIsEmpty() const
{
    QVERIFY(m_nav.currentUrl().isEmpty());
}

void tst_NavigationController::initialState_currentPropsAreEmpty() const
{
    QCOMPARE(m_nav.currentProps(), QVariantMap());
}

void tst_NavigationController::initialState_showChromeIsTrue() const
{
    QVERIFY(m_nav.currentShowChrome());
}

void tst_NavigationController::initialState_canGoBackIsFalse() const
{
    QVERIFY(!m_nav.canGoBack());
}

void tst_NavigationController::initialState_canGoForwardIsFalse() const
{
    QVERIFY(!m_nav.canGoForward());
}

void tst_NavigationController::initialState_historyLimitIsPositive() const
{
    QVERIFY(m_nav.historyLimit() > 0);
}

void tst_NavigationController::push_emitsPushRequested() const
{
    const QSignalSpy spy{&m_nav, &NavigationController::pushRequested};
    m_nav.push(QStringLiteral("pages/Readme.qml"), {{"key", "value"}}, false);
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::push_signalContainsUrl() const
{
    const QSignalSpy spy{&m_nav, &NavigationController::pushRequested};
    m_nav.push(QStringLiteral("pages/Readme.qml"), {{"key", "value"}}, false);
    QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("pages/Readme.qml"));
}

void tst_NavigationController::push_signalContainsProps() const
{
    const QVariantMap props{{"key", "value"}};
    const QSignalSpy spy{&m_nav, &NavigationController::pushRequested};
    m_nav.push(QStringLiteral("pages/Readme.qml"), props, false);
    QCOMPARE(spy.at(0).at(1).toMap(), props);
}

void tst_NavigationController::push_signalContainsShowChrome() const
{
    const QSignalSpy spy{&m_nav, &NavigationController::pushRequested};
    m_nav.push(QStringLiteral("pages/Readme.qml"), {{"key", "value"}}, false);
    QCOMPARE(spy.at(0).at(2).toBool(), false);
}

void tst_NavigationController::push_clearsForwardStack() const
{
    m_nav.setCurrent(QStringLiteral("page1"), QVariantMap(), true, 2);
    m_nav.pop();
    QVERIFY(m_nav.canGoForward());

    m_nav.push(QStringLiteral("page2"));
    QVERIFY(!m_nav.canGoForward());
}

void tst_NavigationController::push_clearingForwardStackEmitsCurrentChanged() const
{
    m_nav.setCurrent(QStringLiteral("page1"), QVariantMap(), true, 2);
    m_nav.pop();

    const QSignalSpy spy{&m_nav, &NavigationController::currentChanged};
    m_nav.push(QStringLiteral("page2"));
    QVERIFY(spy.count() >= 1);
}

void tst_NavigationController::push_atHistoryLimitEmitsReplaceRequested() const
{
    const int limit{m_nav.historyLimit()};
    m_nav.setCurrent(QStringLiteral("deep"), QVariantMap(), true, limit);

    const QSignalSpy spy{&m_nav, &NavigationController::replaceRequested};
    m_nav.push(QStringLiteral("next"));
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::push_atHistoryLimitDoesNotEmitPushRequested() const
{
    const int limit{m_nav.historyLimit()};
    m_nav.setCurrent(QStringLiteral("deep"), QVariantMap(), true, limit);

    const QSignalSpy spy{&m_nav, &NavigationController::pushRequested};
    m_nav.push(QStringLiteral("next"));
    QCOMPARE(spy.count(), 0);
}

void tst_NavigationController::setCurrent_emitsCurrentChanged() const
{
    const QSignalSpy spy{&m_nav, &NavigationController::currentChanged};
    m_nav.setCurrent(QStringLiteral("pages/License.qml"), {{"id", 42}}, false, 2);
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::setCurrent_updatesCurrentUrl() const
{
    m_nav.setCurrent(QStringLiteral("pages/License.qml"), {{"id", 42}}, false, 2);
    QCOMPARE(m_nav.currentUrl(), QStringLiteral("pages/License.qml"));
}

void tst_NavigationController::setCurrent_updatesCurrentProps() const
{
    const QVariantMap props{{"id", 42}};
    m_nav.setCurrent(QStringLiteral("pages/License.qml"), props, false, 2);
    QCOMPARE(m_nav.currentProps(), props);
}

void tst_NavigationController::setCurrent_updatesShowChrome() const
{
    m_nav.setCurrent(QStringLiteral("pages/License.qml"), {{"id", 42}}, false, 2);
    QVERIFY(!m_nav.currentShowChrome());
}

void tst_NavigationController::setCurrent_updatesCanGoBack() const
{
    m_nav.setCurrent(QStringLiteral("pages/License.qml"), {{"id", 42}}, false, 2);
    QVERIFY(m_nav.canGoBack());
}

void tst_NavigationController::setCurrent_identicalValuesEmitNoSignal() const
{
    m_nav.setCurrent(QStringLiteral("page"), QVariantMap(), true, 1);

    const QSignalSpy spy{&m_nav, &NavigationController::currentChanged};
    m_nav.setCurrent(QStringLiteral("page"), QVariantMap(), true, 1);
    QCOMPARE(spy.count(), 0);
}

void tst_NavigationController::pop_atRootEmitsBackAtRoot() const
{
    const QSignalSpy spy{&m_nav, &NavigationController::backAtRoot};
    m_nav.pop();
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::pop_atRootDoesNotEmitPopRequested() const
{
    const QSignalSpy spy{&m_nav, &NavigationController::popRequested};
    m_nav.pop();
    QCOMPARE(spy.count(), 0);
}

void tst_NavigationController::pop_emitsPopRequested() const
{
    m_nav.setCurrent(QStringLiteral("pages/Readme.qml"), QVariantMap(), true, 2);

    const QSignalSpy spy{&m_nav, &NavigationController::popRequested};
    m_nav.pop();
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::pop_enablesCanGoForward() const
{
    m_nav.setCurrent(QStringLiteral("pages/Readme.qml"), QVariantMap(), true, 2);
    m_nav.pop();
    QVERIFY(m_nav.canGoForward());
}

void tst_NavigationController::forward_emptyStackIsNoOp() const
{
    const QSignalSpy spy{&m_nav, &NavigationController::pushRequested};
    m_nav.forward();
    QCOMPARE(spy.count(), 0);
}

void tst_NavigationController::forward_emitsPushRequested() const
{
    m_nav.setCurrent(QStringLiteral("pages/Readme.qml"), {{"key", "val"}}, false, 2);
    m_nav.pop();

    const QSignalSpy spy{&m_nav, &NavigationController::pushRequested};
    m_nav.forward();
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::forward_signalContainsSavedUrl() const
{
    m_nav.setCurrent(QStringLiteral("pages/Readme.qml"), {{"key", "val"}}, false, 2);
    m_nav.pop();

    const QSignalSpy spy{&m_nav, &NavigationController::pushRequested};
    m_nav.forward();
    QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("pages/Readme.qml"));
}

void tst_NavigationController::forward_signalContainsSavedProps() const
{
    const QVariantMap props{{"key", "val"}};
    m_nav.setCurrent(QStringLiteral("pages/Readme.qml"), props, false, 2);
    m_nav.pop();

    const QSignalSpy spy{&m_nav, &NavigationController::pushRequested};
    m_nav.forward();
    QCOMPARE(spy.at(0).at(1).toMap(), props);
}

void tst_NavigationController::forward_signalContainsSavedShowChrome() const
{
    m_nav.setCurrent(QStringLiteral("pages/Readme.qml"), {{"key", "val"}}, false, 2);
    m_nav.pop();

    const QSignalSpy spy{&m_nav, &NavigationController::pushRequested};
    m_nav.forward();
    QCOMPARE(spy.at(0).at(2).toBool(), false);
}

void tst_NavigationController::replace_emitsReplaceRequested() const
{
    const QSignalSpy spy{&m_nav, &NavigationController::replaceRequested};
    m_nav.replace(QStringLiteral("pages/StyleShowcase.qml"), {{"mode", "edit"}}, false);
    QCOMPARE(spy.count(), 1);
}

void tst_NavigationController::replace_signalContainsUrl() const
{
    const QSignalSpy spy{&m_nav, &NavigationController::replaceRequested};
    m_nav.replace(QStringLiteral("pages/StyleShowcase.qml"), {{"mode", "edit"}}, false);
    QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("pages/StyleShowcase.qml"));
}

void tst_NavigationController::replace_signalContainsProps() const
{
    const QVariantMap props{{"mode", "edit"}};
    const QSignalSpy spy{&m_nav, &NavigationController::replaceRequested};
    m_nav.replace(QStringLiteral("pages/StyleShowcase.qml"), props, false);
    QCOMPARE(spy.at(0).at(1).toMap(), props);
}

void tst_NavigationController::replace_signalContainsShowChrome() const
{
    const QSignalSpy spy{&m_nav, &NavigationController::replaceRequested};
    m_nav.replace(QStringLiteral("pages/StyleShowcase.qml"), {{"mode", "edit"}}, false);
    QCOMPARE(spy.at(0).at(2).toBool(), false);
}

void tst_NavigationController::replace_clearsForwardStack() const
{
    m_nav.setCurrent(QStringLiteral("page1"), QVariantMap(), true, 2);
    m_nav.pop();
    QVERIFY(m_nav.canGoForward());

    m_nav.replace(QStringLiteral("page2"));
    QVERIFY(!m_nav.canGoForward());
}
