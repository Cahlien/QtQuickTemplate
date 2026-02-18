#pragma once

// These must be included before qqmlregistration.h so that
// QML_SINGLETON's generated factory code — and the moc — can
// see the complete types used in NavigationController::create().
#include <QJSEngine>
#include <QMutex>
#include <QObject>
#include <QQmlEngine>
#include <QStack>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

/*!
    \class NavigationController
    \brief Thread-safe navigation stack exposed to QML as the \c Router singleton.

    The C++ side owns the navigation state; QML's StackView reacts to the
    signals.  The JNI back-handler (android_back_handler.cpp) calls pop() on
    the Android UI thread – Qt dispatches it to the Qt main thread via a
    queued connection.

    In QML (same module, no extra import needed):
    \code
    Router.push("qrc:/qt/qml/.../License.qml")
    Router.pop()
    \endcode
*/
class NavigationController : public QObject
{
    Q_OBJECT
    // Exposed in QML as "Router" (not "NavigationController" to avoid
    // clashing with the existing NavigationController.qml type).
    QML_NAMED_ELEMENT(Router)
    QML_SINGLETON

    Q_PROPERTY(int  depth      READ depth      NOTIFY depthChanged FINAL)
    Q_PROPERTY(bool canGoBack  READ canGoBack  NOTIFY depthChanged FINAL)

public:
    ~NavigationController() override = default;

    // ── Singleton plumbing ────────────────────────────────────────────────

    /// Called once by the QML engine. Returns the same static instance as
    /// instance() and marks it CppOwnership so the engine never deletes it.
    static NavigationController *create(QQmlEngine *engine,
                                        QJSEngine  *scriptEngine);

    /// C++ accessor used by android_back_handler.cpp (no engine needed).
    static NavigationController *instance();

    // ── Navigation API ────────────────────────────────────────────────────

    /// Push \a path (URL string) with optional \a props onto the stack and
    /// emit pushRequested so QML's StackView can react.
    Q_INVOKABLE void push(const QString &path,
                          const QVariantMap &props = {});

    /// Pop the top entry and emit popRequested.  If the stack is already
    /// empty the signal is still emitted so QML can decide to minimise.
    Q_INVOKABLE void pop();

    /// Replace the top entry (or push if empty) and emit replaceRequested.
    Q_INVOKABLE void replace(const QString &path,
                             const QVariantMap &props = {});

    /// Move the app to the background (Android only; no-op elsewhere).
    /// Call this from QML when back is pressed on the root screen.
    Q_INVOKABLE void minimizeApp();

    [[nodiscard]] int  depth()     const;
    [[nodiscard]] bool canGoBack() const;

signals:
    void pushRequested   (const QString &path, const QVariantMap &props);
    void popRequested    ();
    void replaceRequested(const QString &path, const QVariantMap &props);
    void depthChanged    ();

private:
    explicit NavigationController(QObject *parent = nullptr);

    struct NavEntry {
        QString     path;
        QVariantMap props;
    };

    mutable QMutex   m_mutex;
    QStack<NavEntry> m_stack;
};
