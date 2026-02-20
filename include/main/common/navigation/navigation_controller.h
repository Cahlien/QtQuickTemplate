#pragma once

#include <QJSEngine>
#include <QObject>
#include <QQmlEngine>
#include <QStack>
#include <QString>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

/*!
    \class NavigationController
    \brief Unified navigation manager exposed to QML as the \c NavigationController singleton.

    Maintains a single back-stack of lightweight \c Entry records — each storing
    only a URL, optional initial properties, and a chrome-visibility flag.  No
    QQuickItem references are held; pages are (re)hydrated on demand by the QML
    \c Loader via \c Loader::setSource(url, props).

    QML reacts declaratively to property changes:

    \list
    \li \c currentUrl / \c currentProps / \c currentShowChrome drive the active \c Loader.
    \li \c canGoBack controls whether the back button triggers a pop or a root signal.
    \li \c activeTabIndex tracks the selected top-level tab without changing when
        sub-pages (e.g.\ License) are pushed on top.
    \endlist

    Top-level tab navigation uses \c navigateTab() which clears the back-stack
    and updates \c activeTabIndex.  Sub-page navigation uses \c push() which
    preserves the tab highlight and adds a back-stack entry.

    The \c backAtRoot signal fires when \c pop() is called with an empty back-stack;
    QML uses it to minimise the app on Android or do nothing on desktop.

    All mutating methods are guarded against re-entrant calls during signal
    emission, which prevents platform-specific cascading pushes triggered by
    QML \c Binding side-effects (e.g.\ \c TabBar \c currentIndex changes
    spuriously activating a tab button on iOS).

    Thread safety: \c pop() is always invoked on the Qt main thread via
    \c Qt::QueuedConnection from the JNI back-handler, so no mutex is required.
*/
class NavigationController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString     currentUrl         READ currentUrl         NOTIFY currentChanged   FINAL)
    Q_PROPERTY(QVariantMap currentProps        READ currentProps       NOTIFY currentChanged   FINAL)
    Q_PROPERTY(bool        currentShowChrome   READ currentShowChrome  NOTIFY currentChanged   FINAL)
    Q_PROPERTY(bool        canGoBack           READ canGoBack          NOTIFY currentChanged   FINAL)
    Q_PROPERTY(int         activeTabIndex      READ activeTabIndex     NOTIFY activeTabChanged FINAL)

public:
    ~NavigationController() override = default;

    // ── Singleton plumbing ────────────────────────────────────────────────

    static NavigationController *create(QQmlEngine *engine, QJSEngine *scriptEngine);
    static NavigationController *instance();

    // ── Navigation API ────────────────────────────────────────────────────

    /// Push a new page onto the back-stack.  The first call seeds the home
    /// entry without adding to the back-stack, so back from the home page
    /// never returns to a blank state.
    ///
    /// \note Does not change \c activeTabIndex — use \c navigateTab() for
    /// top-level tab switches.
    Q_INVOKABLE void push(const QString     &url,
                          const QVariantMap &props      = {},
                          bool               showChrome = true);

    /// Pop the top entry.  Emits \c backAtRoot if the stack is already empty.
    Q_INVOKABLE void pop();

    /// Replace the current entry in-place (back-stack is unaffected).
    Q_INVOKABLE void replace(const QString     &url,
                             const QVariantMap &props      = {},
                             bool               showChrome = true);

    /// Switch to a top-level tab page.
    ///
    /// Clears the back-stack (tabs are siblings, not stacked) and sets
    /// \c activeTabIndex so the QML \c TabBar highlight stays in sync without
    /// requiring URL-parsing bindings.  No-ops if already on the given tab/URL.
    Q_INVOKABLE void navigateTab(int                tabIndex,
                                 const QString     &url,
                                 const QVariantMap &props      = {},
                                 bool               showChrome = true);

    /// Move the app to the background (Android only; no-op elsewhere).
    Q_INVOKABLE void minimizeApp();

    // ── Property accessors ────────────────────────────────────────────────

    [[nodiscard]] QString     currentUrl()         const;
    [[nodiscard]] QVariantMap currentProps()        const;
    [[nodiscard]] bool        currentShowChrome()   const;
    [[nodiscard]] bool        canGoBack()           const;
    [[nodiscard]] int         activeTabIndex()      const;

signals:
    void currentChanged();
    /// Emitted when \c activeTabIndex changes (only via \c navigateTab()).
    void activeTabChanged();
    /// Fired when \c pop() is called with an empty back-stack.
    void backAtRoot();

private:
    explicit NavigationController(QObject *parent = nullptr);

    struct Entry {
        QString     url;
        QVariantMap props;
        bool        showChrome = true;
    };

    QStack<Entry> m_back;
    Entry         m_current;
    int           m_activeTabIndex = 0;
    bool          m_navigating     = false;
};
