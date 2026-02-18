import QtQuick

/*!
    \qmltype NavigationController
    \inqmlmodule dev.crowell.QtQuickTemplate
    \inherits QtObject
    \brief Loader-based navigation manager with back/forward history.

    NavigationController maintains back and forward history stacks and
    drives a Loader to display pages by URL. Call \l navigate() to
    push a new page, \l goBack() and \l goForward() to traverse history,
    or \l clearHistory() to reset.

    \sa Main
*/
QtObject {
    id: navigationController

    /*!
        \qmlproperty var NavigationController::loader
        The Loader instance whose \c source is set when navigating.
    */
    required property Loader loader

    /*!
        \qmlproperty url NavigationController::defaultContentSource
        Fallback source applied to the loader when \l navigate() is called
        with an empty target.
    */
    property url defaultContentSource: Qt.resolvedUrl("")

    // ── History state ──
    /*! \internal */
    property var _history: []
    /*! \internal */
    property var _forward: []
    /*! \internal */
    property var _current: null

    /*!
        \qmlproperty bool NavigationController::canGoBack
        \readonly
        \c true when there is at least one entry in the back history stack.
    */
    readonly property bool canGoBack: _history.length > 0

    /*!
        \qmlproperty bool NavigationController::canGoForward
        \readonly
        \c true when there is at least one entry in the forward history stack.
    */
    readonly property bool canGoForward: _forward.length > 0

    /*!
        \qmlproperty int NavigationController::historyDepth
        \readonly
        The number of entries in the back history stack.
    */
    readonly property int historyDepth: _history.length

    /*!
        \qmlsignal NavigationController::navigationRequested(string target, var properties)
        Emitted after the loader source changes, carrying the resolved
        \a target URL and the \a properties map passed to the page.
    */
    signal navigationRequested(string target, var properties)

    /*!
        \qmlsignal NavigationController::historyChanged()
        Emitted whenever the back or forward history stacks are modified.
    */
    signal historyChanged()

    /*!
        \qmlmethod void NavigationController::navigate(url request)
        Navigates to \a request with no additional properties.
        Shorthand for \c {navigateToTarget(request, {})}.
    */
    function navigate(request) {
        navigateToTarget(request, {});
    }

    /*!
        \qmlmethod void NavigationController::navigateToTarget(url target, var properties)
        Pushes the current page onto the back history stack, clears the
        forward stack, resolves \a target, and loads it into the \l loader
        with the given \a properties.
    */
    function navigateToTarget(target, properties) {
        if (!target || target === "") {
            loader.source = defaultContentSource;
            return;
        }

        // Push current state onto history before navigating
        if (_current !== null) {
            var hist = _history.slice();
            hist.push(_current);
            _history = hist;
        }

        // New navigation clears the forward stack
        _forward = [];

        var props = {};
        if (properties) {
            for (var key in properties) {
                props[key] = properties[key];
            }
        }

        var resolved = Qt.resolvedUrl(target);
        _current = { url: resolved, properties: props };

        loader.setSource(resolved, props);
        navigationRequested(resolved.toString(), properties);
        historyChanged();
    }

    /*!
        \qmlmethod void NavigationController::goBack()
        Navigates to the previous page in the back history stack.
        The current page is pushed onto the forward stack. Does nothing
        if \l canGoBack is \c false.
    */
    function goBack() {
        if (!canGoBack) return;

        var hist = _history.slice();
        var fwd = _forward.slice();

        // Push current onto forward stack
        if (_current !== null) {
            fwd.push(_current);
        }

        // Pop from history
        var entry = hist.pop();

        _history = hist;
        _forward = fwd;
        _current = entry;

        loader.setSource(entry.url, entry.properties);
        navigationRequested(entry.url.toString(), entry.properties);
        historyChanged();
    }

    /*!
        \qmlmethod void NavigationController::goForward()
        Navigates to the next page in the forward history stack.
        The current page is pushed onto the back stack. Does nothing
        if \l canGoForward is \c false.
    */
    function goForward() {
        if (!canGoForward) return;

        var hist = _history.slice();
        var fwd = _forward.slice();

        // Push current onto history
        if (_current !== null) {
            hist.push(_current);
        }

        // Pop from forward stack
        var entry = fwd.pop();

        _history = hist;
        _forward = fwd;
        _current = entry;

        loader.setSource(entry.url, entry.properties);
        navigationRequested(entry.url.toString(), entry.properties);
        historyChanged();
    }

    /*!
        \qmlmethod void NavigationController::clearHistory()
        Clears both the back and forward history stacks and resets
        the current entry. The loader source is not changed.
    */
    function clearHistory() {
        _history = [];
        _forward = [];
        _current = null;
        historyChanged();
    }
}
