#include "navigation/navigation_controller.h"

#include <QJSEngine>
#include <QQmlEngine>
#include <QDebug>
#include <utility>

#if defined(Q_OS_ANDROID) && __has_include(<QJniObject>)
#include <QCoreApplication>
#include <QJniObject>
#endif

// ── Singleton ─────────────────────────────────────────────────────────────────

NavigationController::NavigationController(QObject *parent)
    : QObject(parent)
{}

NavigationController *NavigationController::instance()
{
    static NavigationController s_instance;
    return &s_instance;
}

NavigationController *NavigationController::create(QQmlEngine * /*engine*/,
                                                   QJSEngine  * /*scriptEngine*/)
{
    QJSEngine::setObjectOwnership(instance(), QJSEngine::CppOwnership);
    return instance();
}

// ── Navigation ────────────────────────────────────────────────────────────────

void NavigationController::push(const QString     &url,
                                const QVariantMap &props,
                                bool               showChrome)
{
    requestTransition({ ActionType::Push, url, props, showChrome });
}

void NavigationController::pop()
{
    requestTransition({ ActionType::Pop, {}, {}, true });
}

void NavigationController::replace(const QString     &url,
                                   const QVariantMap &props,
                                   bool               showChrome)
{
    requestTransition({ ActionType::Replace, url, props, showChrome });
}

void NavigationController::completeTransition()
{
    if (!m_transitionInProgress)
        return;

    switch (m_pendingAction.type) {
    case ActionType::Push:
        if (!m_current.url.isEmpty())
            m_back.push(m_current);
        m_current = m_pendingEntry;
        qDebug() << "NC::commit push  url=" << m_current.url << "  backSize=" << m_back.size();
        break;

    case ActionType::Pop:
        if (m_back.isEmpty()) {
            m_transitionInProgress = false;
            return;
        }
        m_current = m_back.pop();
        qDebug() << "NC::commit pop   url=" << m_current.url << "  backSize=" << m_back.size();
        break;

    case ActionType::Replace:
        m_current = m_pendingEntry;
        qDebug() << "NC::commit replace url=" << m_current.url << "  backSize=" << m_back.size();
        break;
    }

    m_transitionInProgress = false;
    emit currentChanged();

    if (m_hasQueuedAction) {
        const Action queued = m_queuedAction;
        m_hasQueuedAction = false;
        startTransition(queued);
    }
}

void NavigationController::requestTransition(Action action)
{
    if (m_transitionInProgress) {
        m_queuedAction = std::move(action);
        m_hasQueuedAction = true;
        return;
    }

    startTransition(action);
}

bool NavigationController::startTransition(const Action &action)
{
    if (action.type == ActionType::Pop) {
        qDebug() << "NC::pop request  backSize=" << m_back.size();
        if (m_back.isEmpty()) {
            qDebug() << "NC::pop request  → backAtRoot";
            emit backAtRoot();
            return false;
        }
        m_pendingEntry = m_back.top();
    } else {
        m_pendingEntry = { action.url, action.props, action.showChrome };
    }

    m_pendingAction = action;
    m_transitionInProgress = true;

    qDebug() << "NC::transition request  url=" << m_pendingEntry.url;
    emit transitionRequested(m_pendingEntry.url,
                             m_pendingEntry.props,
                             m_pendingEntry.showChrome);
    return true;
}

void NavigationController::minimizeApp()
{
#if defined(Q_OS_ANDROID) && __has_include(<QJniObject>)
    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([]() {
        QJniObject activity = QJniObject::callStaticObjectMethod(
            "org/qtproject/qt/android/QtNative",
            "activity",
            "()Landroid/app/Activity;");

        if (activity.isValid())
            activity.callMethod<jboolean>("moveTaskToBack", "(Z)Z", true);
    });
#endif
}

// ── Property accessors ────────────────────────────────────────────────────────

QString NavigationController::currentUrl() const
{
    return m_current.url;
}

QVariantMap NavigationController::currentProps() const
{
    return m_current.props;
}

bool NavigationController::currentShowChrome() const
{
    return m_current.showChrome;
}

bool NavigationController::canGoBack() const
{
    return !m_back.isEmpty();
}
