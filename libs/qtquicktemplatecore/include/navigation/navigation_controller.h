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
    \li \c navigationDirection tells the transition animator which direction to slide.
    \endlist

    The \c backAtRoot signal fires when \c pop() is called with an empty back-stack;
    QML uses it to minimise the app on Android or do nothing on desktop.

    Thread safety: \c pop() is always invoked on the Qt main thread via
    \c Qt::QueuedConnection from the JNI back-handler, so no mutex is required.
*/
class NavigationController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString     currentUrl         READ currentUrl         NOTIFY currentChanged FINAL)
    Q_PROPERTY(QVariantMap currentProps        READ currentProps        NOTIFY currentChanged FINAL)
    Q_PROPERTY(bool        currentShowChrome   READ currentShowChrome   NOTIFY currentChanged FINAL)
    Q_PROPERTY(bool        canGoBack           READ canGoBack           NOTIFY currentChanged FINAL)

public:
    ~NavigationController() override = default;

    enum class ActionType {
        Push,
        Pop,
        Replace
    };

    struct Action {
        ActionType  type = ActionType::Push;
        QString     url;
        QVariantMap props;
        bool        showChrome = true;
    };

    // ── Singleton plumbing ────────────────────────────────────────────────

    static NavigationController *create(QQmlEngine *engine, QJSEngine *scriptEngine);
    static NavigationController *instance();

    // ── Navigation API ────────────────────────────────────────────────────

    /// Push a new page.  The first call seeds the home entry without adding to
    /// the back-stack, so back from the home page never returns to a blank state.
    Q_INVOKABLE void push(const QString     &url,
                          const QVariantMap &props      = {},
                          bool               showChrome = true);

    /// Pop the top entry.  Emits \c backAtRoot if the stack is already empty.
    Q_INVOKABLE void pop();

    /// Replace the current entry in-place (back-stack is unaffected).
    Q_INVOKABLE void replace(const QString     &url,
                             const QVariantMap &props      = {},
                             bool               showChrome = true);

    /// Commit the pending transition after QML loads the new page.
    Q_INVOKABLE void completeTransition();

    /// Move the app to the background (Android only; no-op elsewhere).
    Q_INVOKABLE void minimizeApp();

    // ── Property accessors ────────────────────────────────────────────────

    [[nodiscard]] QString     currentUrl()         const;
    [[nodiscard]] QVariantMap currentProps()        const;
    [[nodiscard]] bool        currentShowChrome()   const;
    [[nodiscard]] bool        canGoBack()           const;

signals:
    /// Emitted when QML should transition to a new target page.
    void transitionRequested(const QString &url,
                             const QVariantMap &props,
                             bool showChrome);

    void currentChanged();
    /// Fired when \c pop() is called with an empty back-stack.
    void backAtRoot();

private:
    explicit NavigationController(QObject *parent = nullptr);

    void requestTransition(Action action);
    bool startTransition(const Action &action);

    struct Entry {
        QString     url;
        QVariantMap props;
        bool        showChrome = true;
    };

    QStack<Entry> m_back;
    Entry         m_current;

    bool   m_transitionInProgress = false;
    Action m_pendingAction;
    Entry  m_pendingEntry;

    bool   m_hasQueuedAction = false;
    Action m_queuedAction;
};
