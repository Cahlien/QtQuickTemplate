import QtQuick

QtObject {
    id: navigationController

    required property Loader loader
    property url defaultContentSource: Qt.resolvedUrl("")

    // ── History state ──
    property var _history: []
    property var _forward: []
    property var _current: null

    readonly property bool canGoBack: _history.length > 0
    readonly property bool canGoForward: _forward.length > 0
    readonly property int historyDepth: _history.length

    signal navigationRequested(string target, var properties)
    signal historyChanged()

    function navigate(request) {
        navigateToTarget(request, {});
    }

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
        navigationRequested(target.toString(), properties);
        historyChanged();
    }

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

    function clearHistory() {
        _history = [];
        _forward = [];
        _current = null;
        historyChanged();
    }
}
