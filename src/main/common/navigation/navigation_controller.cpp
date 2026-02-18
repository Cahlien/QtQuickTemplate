#include "navigation_controller.h"

#include <QJSEngine>
#include <QMutexLocker>
#include <QQmlEngine>

// minimizeApp() is platform-specific and defined elsewhere:
//   Android  → src/main/android/android_back_handler.cpp
//   All else → src/main/common/platform_init_default.cpp

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
    // Tell the engine it does NOT own this object — the static lifetime
    // must outlast the QML engine.
    QJSEngine::setObjectOwnership(instance(), QJSEngine::CppOwnership);
    return instance();
}

// ── Overlay navigation (StackView) ────────────────────────────────────────────

void NavigationController::push(const QString &path, const QVariantMap &props)
{
    {
        QMutexLocker lock(&m_mutex);
        m_stack.push({path, props});
    }
    emit pushRequested(path, props);
    emit depthChanged();
}

void NavigationController::pop()
{
    bool stackWasEmpty = false;
    {
        QMutexLocker lock(&m_mutex);
        if (m_stack.isEmpty())
            stackWasEmpty = true;
        else
            m_stack.pop();
    }
    // Always emit — even when empty — so QML can minimise or do content back.
    emit popRequested();
    if (!stackWasEmpty)
        emit depthChanged();
}

void NavigationController::replace(const QString &path, const QVariantMap &props)
{
    {
        QMutexLocker lock(&m_mutex);
        if (!m_stack.isEmpty())
            m_stack.pop();
        m_stack.push({path, props});
    }
    emit replaceRequested(path, props);
    emit depthChanged();
}

// ── Content navigation (Loader) ───────────────────────────────────────────────

void NavigationController::navigateTo(const QString &url, const QVariantMap &props)
{
    // On the very first call m_contentInitialized is false: seed the home entry
    // rather than pushing it, so the home page never appears in the back stack.
    if (m_contentInitialized)
        m_contentBack.push(m_currentContent);

    m_contentForward.clear();
    m_currentContent     = { url, props };
    m_contentInitialized = true;

    emit contentHistoryChanged();
}

void NavigationController::contentBack()
{
    if (m_contentBack.isEmpty()) return;

    m_contentForward.push(m_currentContent);
    m_currentContent = m_contentBack.pop();

    emit contentHistoryChanged();
}

void NavigationController::contentForward()
{
    if (m_contentForward.isEmpty()) return;

    m_contentBack.push(m_currentContent);
    m_currentContent = m_contentForward.pop();

    emit contentHistoryChanged();
}

// ── Properties ────────────────────────────────────────────────────────────────

int NavigationController::depth() const
{
    QMutexLocker lock(&m_mutex);
    return static_cast<int>(m_stack.size());
}

bool NavigationController::canGoBack() const
{
    QMutexLocker lock(&m_mutex);
    return !m_stack.isEmpty();
}

QString NavigationController::currentContentUrl() const
{
    return m_currentContent.url;
}

bool NavigationController::canGoContentBack() const
{
    return !m_contentBack.isEmpty();
}

bool NavigationController::canGoContentForward() const
{
    return !m_contentForward.isEmpty();
}
