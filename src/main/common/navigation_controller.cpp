#include "navigation_controller.h"

#include <QJSEngine>
#include <QMutexLocker>
#include <QQmlEngine>

// Note: minimizeApp() is intentionally NOT defined here.
// It follows the same platform-file pattern as onFirstFrame():
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

// ── Navigation API ────────────────────────────────────────────────────────────

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
        if (m_stack.isEmpty()) {
            stackWasEmpty = true;
        } else {
            m_stack.pop();
        }
    }
    // Always emit popRequested — even when empty — so QML can decide to
    // minimise the app or perform content-level back navigation.
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
