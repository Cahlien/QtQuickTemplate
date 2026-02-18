#pragma once

// These must be included before qqmlregistration.h so that
// QML_SINGLETON's generated factory code — and the moc — can
// see the complete types used in NavigationController::create().
#include <QJSEngine>
#include <QMutex>
#include <QObject>
#include <QQmlEngine>
#include <QStack>
#include <QString>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

/*!
    \class NavigationController
    \brief Thread-safe navigation manager exposed to QML as the \c NavigationController singleton.

    Owns two independent navigation stacks:

    \list
    \li \b Overlay stack — StackView pages (e.g. License).  Guarded by a
        mutex because pop() may arrive from the Android UI thread via JNI.
    \li \b Content stack — Loader pages (e.g. Readme ↔ StyleShowcase).
        Manipulated on the Qt main thread only; no mutex required.
    \endlist

    QML reads navigation state through properties and reacts to the
    \c contentHistoryChanged and \c depthChanged NOTIFY signals.
    The overlay signals (\c pushRequested, \c popRequested, \c replaceRequested)
    remain imperative because StackView operations cannot be expressed as
    a single declarative binding.

    In QML (same module, no extra import needed):
    \code
    // Overlay pages
    NavigationController.push("qrc:/qt/qml/.../License.qml")
    NavigationController.pop()

    // Content pages
    NavigationController.navigateTo(Qt.resolvedUrl("StyleShowcase.qml").toString())
    NavigationController.contentBack()

    // Declarative binding
    Loader { source: NavigationController.currentContentUrl }
    \endcode
*/
class NavigationController : public QObject
{
    Q_OBJECT
    // QML_ELEMENT registers the type under the C++ class name "NavigationController".
    // No separate QML_NAMED_ELEMENT needed; QML_SINGLETON alone is not sufficient
    // — it must be paired with QML_ELEMENT or QML_NAMED_ELEMENT.
    QML_ELEMENT
    QML_SINGLETON

    // ── Overlay stack properties ───────────────────────────────────────────
    Q_PROPERTY(int  depth     READ depth     NOTIFY depthChanged FINAL)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY depthChanged FINAL)

    // ── Content stack properties ───────────────────────────────────────────
    // All three share contentHistoryChanged as their NOTIFY signal because
    // every navigation event updates all three simultaneously.
    Q_PROPERTY(QString currentContentUrl
               READ currentContentUrl NOTIFY contentHistoryChanged FINAL)
    Q_PROPERTY(bool canGoContentBack
               READ canGoContentBack  NOTIFY contentHistoryChanged FINAL)
    Q_PROPERTY(bool canGoContentForward
               READ canGoContentForward NOTIFY contentHistoryChanged FINAL)

public:
    ~NavigationController() override = default;

    // ── Singleton plumbing ────────────────────────────────────────────────

    /// Called once by the QML engine. Returns the same static instance as
    /// instance() and marks it CppOwnership so the engine never deletes it.
    static NavigationController *create(QQmlEngine *engine,
                                        QJSEngine  *scriptEngine);

    /// C++ accessor used by android_back_handler.cpp (no engine needed).
    static NavigationController *instance();

    // ── Overlay navigation (StackView) ────────────────────────────────────

    Q_INVOKABLE void push(const QString &path, const QVariantMap &props = {});
    Q_INVOKABLE void pop();
    Q_INVOKABLE void replace(const QString &path, const QVariantMap &props = {});

    // ── Content navigation (Loader) ───────────────────────────────────────

    /// Push the current page to the back stack and make \a url current.
    /// On the very first call (before any navigation) the current entry is
    /// seeded rather than pushed, so the home page never appears in history.
    Q_INVOKABLE void navigateTo(const QString &url,
                                const QVariantMap &props = {});

    /// Load the previous content page, pushing current onto the forward stack.
    Q_INVOKABLE void contentBack();

    /// Load the next content page, pushing current onto the back stack.
    Q_INVOKABLE void contentForward();

    // ── Platform ──────────────────────────────────────────────────────────

    /// Move the app to the background (Android only; no-op elsewhere).
    Q_INVOKABLE void minimizeApp();

    // ── Property accessors ────────────────────────────────────────────────

    [[nodiscard]] int     depth()              const;
    [[nodiscard]] bool    canGoBack()          const;
    [[nodiscard]] QString currentContentUrl()  const;
    [[nodiscard]] bool    canGoContentBack()   const;
    [[nodiscard]] bool    canGoContentForward() const;

signals:
    // Overlay — imperative because StackView push/pop cannot be bound
    void pushRequested   (const QString &path, const QVariantMap &props);
    void popRequested    ();
    void replaceRequested(const QString &path, const QVariantMap &props);
    void depthChanged    ();

    // Content — NOTIFY signal for all three content properties
    void contentHistoryChanged();

private:
    explicit NavigationController(QObject *parent = nullptr);

    // ── Overlay stack (mutex-guarded, JNI-accessible) ─────────────────────
    struct OverlayEntry { QString path; QVariantMap props; };
    mutable QMutex       m_mutex;
    QStack<OverlayEntry> m_stack;

    // ── Content stack (Qt main thread only) ───────────────────────────────
    struct ContentEntry { QString url; QVariantMap props; };
    QStack<ContentEntry> m_contentBack;
    QStack<ContentEntry> m_contentForward;
    ContentEntry         m_currentContent;   // url == "" until first navigateTo
    bool                 m_contentInitialized = false;
};
