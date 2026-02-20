#include "navigation_controller.h"

#include <QJSEngine>
#include <QQmlEngine>
#include <QDebug>

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
//
// Every mutating method is guarded by m_navigating to prevent re-entrant
// calls during signal emission.  On iOS the QML Binding that syncs the
// TabBar highlight can cause a programmatic currentIndex change which,
// through UIKit touch-event handling, spuriously activates a TabButton
// and triggers a second push() inside the first push()'s signal cascade.
// The guard silently drops the nested call so the intended navigation wins.

void NavigationController::push(const QString     &url,
                                const QVariantMap &props,
                                bool               showChrome)
{
    if (m_navigating) return;
    m_navigating = true;

    // First push seeds the home entry without touching the back-stack, so the
    // back button from the home page never returns to a blank state.
    if (!m_current.url.isEmpty())
        m_back.push(m_current);

    m_current = { url, props, showChrome };
    qDebug() << "NC::push  url=" << url << "  backSize=" << m_back.size();
    emit currentChanged();

    m_navigating = false;
}

void NavigationController::pop()
{
    if (m_navigating) return;
    m_navigating = true;

    qDebug() << "NC::pop   backSize=" << m_back.size();
    if (m_back.isEmpty()) {
        qDebug() << "NC::pop   → backAtRoot";
        emit backAtRoot();
        m_navigating = false;
        return;
    }
    m_current = m_back.pop();
    qDebug() << "NC::pop   → restored url=" << m_current.url;
    emit currentChanged();

    m_navigating = false;
}

void NavigationController::replace(const QString     &url,
                                   const QVariantMap &props,
                                   bool               showChrome)
{
    if (m_navigating) return;
    m_navigating = true;

    m_current = { url, props, showChrome };
    qDebug() << "NC::replace  url=" << url;
    emit currentChanged();

    m_navigating = false;
}

void NavigationController::navigateTab(int                tabIndex,
                                       const QString     &url,
                                       const QVariantMap &props,
                                       bool               showChrome)
{
    if (m_navigating) return;
    m_navigating = true;

    // Already on this exact tab/page — nothing to do.
    if (url == m_current.url && tabIndex == m_activeTabIndex) {
        m_navigating = false;
        return;
    }

    // Tabs are top-level siblings: clear any sub-page back-stack entries
    // so that "back" from a tab always reaches the root.
    m_back.clear();

    m_current = { url, props, showChrome };

    const bool tabChanged = (m_activeTabIndex != tabIndex);
    m_activeTabIndex = tabIndex;

    qDebug() << "NC::navigateTab  tab=" << tabIndex
             << "  url=" << url << "  backSize=" << m_back.size();

    if (tabChanged)
        emit activeTabChanged();
    emit currentChanged();

    m_navigating = false;
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

int NavigationController::activeTabIndex() const
{
    return m_activeTabIndex;
}
