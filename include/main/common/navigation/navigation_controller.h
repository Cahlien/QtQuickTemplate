#pragma once

#include <QJSEngine>
#include <QObject>
#include <QQmlEngine>
#include <QVector>
#include <QString>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

/*!
    \class NavigationController
    \brief Unified navigation manager exposed to QML as the \c NavigationController singleton.

    Emits navigation requests (\c pushRequested, \c popRequested,
    \c replaceRequested) consumed by a QML \c StackView, and mirrors the
    current top-page state so QML can still bind to a single singleton.

    QML reacts declaratively to property changes:

    \list
    \li \c currentUrl / \c currentProps / \c currentShowChrome drive the active \c Loader.
    \li \c canGoBack controls whether the back button triggers a pop or a root signal.
    \endlist

    The navigation contract remains uniform: every caller uses the same
    three-field tuple (\c url, \c props, \c showChrome).

    The \c backAtRoot signal fires when \c pop() is called with an empty back-stack;
    QML uses it to minimise the app on Android or do nothing on desktop.

    Thread safety: \c pop() is always invoked on the Qt main thread via
    \c Qt::QueuedConnection from the JNI back-handler, so no mutex is required.
*/
namespace dev::crowell::qtquicktemplate {

class NavigationController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString     currentUrl        READ currentUrl        NOTIFY currentChanged FINAL)
    Q_PROPERTY(QVariantMap currentProps       READ currentProps       NOTIFY currentChanged FINAL)
    Q_PROPERTY(bool        currentShowChrome  READ currentShowChrome  NOTIFY currentChanged FINAL)
    Q_PROPERTY(bool        canGoBack          READ canGoBack          NOTIFY currentChanged FINAL)
    Q_PROPERTY(bool        canGoForward       READ canGoForward       NOTIFY currentChanged FINAL)
    Q_PROPERTY(int         historyLimit       READ historyLimit       CONSTANT FINAL)

public:
    ~NavigationController() override = default;

    // ── Singleton plumbing ────────────────────────────────────────────────

    static NavigationController *create(QQmlEngine *engine, QJSEngine *scriptEngine);
    static NavigationController *instance();

    // ── Navigation API ────────────────────────────────────────────────────

    /// Request that QML pushes a page onto StackView.
    Q_INVOKABLE void push(const QString     &url,
                          const QVariantMap &props      = {},
                          bool               showChrome = true);

    /// Request a pop. Emits \c backAtRoot if there is no page to pop.
    Q_INVOKABLE void pop();

    /// Request a forward navigation if forward history exists.
    Q_INVOKABLE void forward();

    /// Request that QML replaces the top page.
    Q_INVOKABLE void replace(const QString     &url,
                             const QVariantMap &props      = {},
                             bool               showChrome = true);

    /// Called by QML whenever StackView top page changes.
    Q_INVOKABLE void setCurrent(const QString     &url,
                                const QVariantMap &props,
                                bool               showChrome,
                                int                stackDepth);

    /// Move the app to the background (Android only; no-op elsewhere).
    Q_INVOKABLE void minimizeApp();

    // ── Property accessors ────────────────────────────────────────────────

    [[nodiscard]] QString     currentUrl()        const;
    [[nodiscard]] QVariantMap currentProps()       const;
    [[nodiscard]] bool        currentShowChrome()  const;
    [[nodiscard]] bool        canGoBack()          const;
    [[nodiscard]] bool        canGoForward()       const;
    [[nodiscard]] int         historyLimit()       const;

signals:
    void currentChanged();
    void pushRequested(const QString &url, const QVariantMap &props, bool showChrome);
    void popRequested();
    void replaceRequested(const QString &url, const QVariantMap &props, bool showChrome);
    /// Fired when \c pop() is called with an empty back-stack.
    void backAtRoot();

private:
    explicit NavigationController(QObject *parent = nullptr);

    struct Entry {
        QString     url;
        QVariantMap props;
        bool        showChrome = true;
    };

    QString     m_currentUrl;
    QVariantMap m_currentProps;
    bool        m_currentShowChrome = true;
    bool        m_canGoBack = false;
    int         m_stackDepth = 0;
    int         m_historyLimit = 1;
    QVector<Entry> m_forward;
};

} // namespace dev::crowell::qtquicktemplate
