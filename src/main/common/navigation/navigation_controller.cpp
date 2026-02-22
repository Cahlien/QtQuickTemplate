#include "navigation/navigation_controller.h"

#include <QJSEngine>
#include <QQmlEngine>
#include <QtGlobal>

#if defined(Q_OS_ANDROID) && __has_include(<QJniObject>)
#include <QCoreApplication>
#include <QJniObject>
#endif

namespace dev::crowell::qtquicktemplate::navigation {

// ── Singleton ─────────────────────────────────────────────────────────────────

NavigationController::NavigationController(QObject *parent)
    : QObject(parent)
{
    int platformDefault = 16;
#if defined(Q_OS_ANDROID)
    platformDefault = 6;
#elif defined(Q_OS_IOS)
    platformDefault = 8;
#endif

    bool hasEnvLimit = false;
    int envLimit = qEnvironmentVariableIntValue("APP_HISTORY_LIMIT", &hasEnvLimit);
    if (!hasEnvLimit)
        envLimit = qEnvironmentVariableIntValue("QTQUICKTEMPLATE_HISTORY_LIMIT", &hasEnvLimit);

    m_historyLimit = hasEnvLimit ? qBound(1, envLimit, 512) : platformDefault;
}

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

void NavigationController::push(const QString     &url,
                                const QVariantMap &props,
                                bool               showChrome)
{
    if (!m_forward.isEmpty()) {
        m_forward.clear();
        emit currentChanged();
    }

    if (m_stackDepth >= m_historyLimit)
        emit replaceRequested(url, props, showChrome);
    else
        emit pushRequested(url, props, showChrome);
}

void NavigationController::pop()
{
    if (!m_canGoBack) {
        emit backAtRoot();
        return;
    }

    const bool hadForward = !m_forward.isEmpty();
    m_forward.push_back({ m_currentUrl, m_currentProps, m_currentShowChrome });
    if (!hadForward)
        emit currentChanged();

    emit popRequested();
}

void NavigationController::forward()
{
    if (m_forward.isEmpty())
        return;

    const Entry next = m_forward.takeLast();
    emit pushRequested(next.url, next.props, next.showChrome);
    emit currentChanged();
}

void NavigationController::replace(const QString     &url,
                                   const QVariantMap &props,
                                   bool               showChrome)
{
    if (!m_forward.isEmpty()) {
        m_forward.clear();
        emit currentChanged();
    }

    emit replaceRequested(url, props, showChrome);
}

void NavigationController::setCurrent(const QString     &url,
                                      const QVariantMap &props,
                                      bool               showChrome,
                                      int                stackDepth)
{
    const bool canGoBack = stackDepth > 1;

    if (m_currentUrl == url
            && m_currentProps == props
            && m_currentShowChrome == showChrome
            && m_canGoBack == canGoBack
            && m_stackDepth == stackDepth)
        return;

    m_currentUrl = url;
    m_currentProps = props;
    m_currentShowChrome = showChrome;
    m_canGoBack = canGoBack;
    m_stackDepth = stackDepth;

    emit currentChanged();
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
    return m_currentUrl;
}

QVariantMap NavigationController::currentProps() const
{
    return m_currentProps;
}

bool NavigationController::currentShowChrome() const
{
    return m_currentShowChrome;
}

bool NavigationController::canGoBack() const
{
    return m_canGoBack;
}

bool NavigationController::canGoForward() const
{
    return !m_forward.isEmpty();
}

int NavigationController::historyLimit() const
{
    return m_historyLimit;
}

} // namespace dev::crowell::qtquicktemplate::navigation
