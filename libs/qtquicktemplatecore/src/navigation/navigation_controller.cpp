#include "navigation/navigation_controller.h"

#include <QJSEngine>
#include <QQmlEngine>
#include <QDebug>

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
    QJSEngine::setObjectOwnership(instance(), QJSEngine::CppOwnership);
    return instance();
}

// ── Navigation ────────────────────────────────────────────────────────────────

void NavigationController::push(const QString     &url,
                                const QVariantMap &props,
                                bool               showChrome)
{
    // First push seeds the home entry without touching the back-stack, so the
    // back button from the home page never returns to a blank state.
    if (!m_current.url.isEmpty())
        m_back.push(m_current);

    m_current = { url, props, showChrome };
    qDebug() << "NC::push  url=" << url << "  backSize=" << m_back.size();
    emit currentChanged();
}

void NavigationController::pop()
{
    qDebug() << "NC::pop   backSize=" << m_back.size();
    if (m_back.isEmpty()) {
        qDebug() << "NC::pop   → backAtRoot";
        emit backAtRoot();
        return;
    }
    m_current = m_back.pop();
    qDebug() << "NC::pop   → restored url=" << m_current.url;
    emit currentChanged();
}

void NavigationController::replace(const QString     &url,
                                   const QVariantMap &props,
                                   bool               showChrome)
{
    m_current = { url, props, showChrome };
    emit currentChanged();
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
