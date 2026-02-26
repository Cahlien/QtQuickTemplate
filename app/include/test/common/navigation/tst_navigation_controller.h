#pragma once

#include <QObject>
#include <QTest>

#include "navigation/navigation_controller.h"

using NavigationController = dev::crowell::qtquicktemplate::navigation::NavigationController;

class tst_NavigationController : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void init();

    // initialState
    void initialState_currentUrlIsEmpty();
    void initialState_currentPropsAreEmpty();
    void initialState_showChromeIsTrue();
    void initialState_canGoBackIsFalse();
    void initialState_canGoForwardIsFalse();
    void initialState_historyLimitIsPositive();

    // push
    void push_emitsPushRequested();
    void push_signalContainsUrl();
    void push_signalContainsProps();
    void push_signalContainsShowChrome();
    void push_clearsForwardStack();
    void push_clearingForwardStackEmitsCurrentChanged();
    void push_atHistoryLimitEmitsReplaceRequested();
    void push_atHistoryLimitDoesNotEmitPushRequested();

    // setCurrent
    void setCurrent_emitsCurrentChanged();
    void setCurrent_updatesCurrentUrl();
    void setCurrent_updatesCurrentProps();
    void setCurrent_updatesShowChrome();
    void setCurrent_updatesCanGoBack();
    void setCurrent_identicalValuesEmitNoSignal();

    // pop
    void pop_atRootEmitsBackAtRoot();
    void pop_atRootDoesNotEmitPopRequested();
    void pop_emitsPopRequested();
    void pop_enablesCanGoForward();

    // forward
    void forward_emptyStackIsNoOp();
    void forward_emitsPushRequested();
    void forward_signalContainsSavedUrl();
    void forward_signalContainsSavedProps();
    void forward_signalContainsSavedShowChrome();

    // replace
    void replace_emitsReplaceRequested();
    void replace_signalContainsUrl();
    void replace_signalContainsProps();
    void replace_signalContainsShowChrome();
    void replace_clearsForwardStack();

private:
    NavigationController *nav{};
};
