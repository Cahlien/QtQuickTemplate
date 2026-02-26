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
    void init() const;

    void initialState_currentUrlIsEmpty() const;
    void initialState_currentPropsAreEmpty() const;
    void initialState_showChromeIsTrue() const;
    void initialState_canGoBackIsFalse() const;
    void initialState_canGoForwardIsFalse() const;
    void initialState_historyLimitIsPositive() const;

    void push_emitsPushRequested() const;
    void push_signalContainsUrl() const;
    void push_signalContainsProps() const;
    void push_signalContainsShowChrome() const;
    void push_clearsForwardStack() const;
    void push_clearingForwardStackEmitsCurrentChanged() const;
    void push_atHistoryLimitEmitsReplaceRequested() const;
    void push_atHistoryLimitDoesNotEmitPushRequested() const;

    void setCurrent_emitsCurrentChanged() const;
    void setCurrent_updatesCurrentUrl() const;
    void setCurrent_updatesCurrentProps() const;
    void setCurrent_updatesShowChrome() const;
    void setCurrent_updatesCanGoBack() const;
    void setCurrent_identicalValuesEmitNoSignal() const;

    void pop_atRootEmitsBackAtRoot() const;
    void pop_atRootDoesNotEmitPopRequested() const;
    void pop_emitsPopRequested() const;
    void pop_enablesCanGoForward() const;

    void forward_emptyStackIsNoOp() const;
    void forward_emitsPushRequested() const;
    void forward_signalContainsSavedUrl() const;
    void forward_signalContainsSavedProps() const;
    void forward_signalContainsSavedShowChrome() const;

    void replace_emitsReplaceRequested() const;
    void replace_signalContainsUrl() const;
    void replace_signalContainsProps() const;
    void replace_signalContainsShowChrome() const;
    void replace_clearsForwardStack() const;

private:
    NavigationController *nav{};
};
