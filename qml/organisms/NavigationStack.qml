import QtQuick
import QtQuick.Controls

Item {
    id: root

    property bool displayedShowChrome: true
    property string pendingNavigationKey: ""

    function navigationKey(url, props, showChrome) {
        const nextProps = props || ({})
        let propsKey = ""
        try {
            propsKey = JSON.stringify(nextProps)
        } catch (error) {
            propsKey = "[unserializable]"
        }
        return (url || "") + "|" + (showChrome ? "1" : "0") + "|" + propsKey
    }

    function isCurrentPage(url, props, showChrome) {
        const currentItem = stackView.currentItem
        if (!currentItem)
            return false

        const currentUrl = currentItem.navigationUrl || ""
        const currentProps = currentItem.pageProps || ({})
        const currentShowChrome = typeof currentItem.showChrome === "boolean"
                                ? currentItem.showChrome
                                : true
        const nextProps = props || ({})

        if (currentUrl !== (url || "") || currentShowChrome !== showChrome)
            return false

        try {
            return JSON.stringify(currentProps) === JSON.stringify(nextProps)
        } catch (error) {
            return false
        }
    }

    function syncNavigationState() {
        if (!stackView.currentItem)
            return

        const currentItem = stackView.currentItem

        // During StackView transitions, depthChanged can fire before
        // currentItemChanged.  In that window currentItem still references
        // the outgoing page.  Skip the stale sync — currentItemChanged
        // will follow immediately with the correct item.
        if (currentItem.StackView.status === StackView.Deactivating)
            return

        const currentShowChrome = typeof currentItem.showChrome === "boolean"
                                ? currentItem.showChrome
                                : true

        displayedShowChrome = currentShowChrome
        pendingNavigationKey = root.navigationKey(
            currentItem.navigationUrl || "",
            currentItem.pageProps || ({}),
            currentShowChrome
        )
        NavigationController.setCurrent(
            currentItem.navigationUrl || "",
            currentItem.pageProps || ({}),
            currentShowChrome,
            stackView.depth
        )
    }

    StackView {
        id: stackView
        anchors.fill: parent

        pushEnter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: stackView.width
                    to: 0
                    duration: 260
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0.92
                    to: 1
                    duration: 220
                    easing.type: Easing.OutQuad
                }
            }
        }

        pushExit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: 0
                    to: -stackView.width * 0.28
                    duration: 260
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0.9
                    duration: 240
                    easing.type: Easing.OutQuad
                }
            }
        }

        popEnter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: -stackView.width * 0.28
                    to: 0
                    duration: 260
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0.9
                    to: 1
                    duration: 220
                    easing.type: Easing.OutQuad
                }
            }
        }

        popExit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: 0
                    to: stackView.width
                    duration: 260
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0.95
                    duration: 220
                    easing.type: Easing.OutQuad
                }
            }
        }

        onCurrentItemChanged: root.syncNavigationState()
        onDepthChanged: root.syncNavigationState()
    }

    Connections {
        target: NavigationController

        function onPushRequested(url, props, showChrome) {
            const nextKey = root.navigationKey(url, props, showChrome)
            if (root.isCurrentPage(url, props, showChrome)
                    || root.pendingNavigationKey === nextKey)
                return

            root.pendingNavigationKey = nextKey
            stackView.push(url, {
                navigationUrl: url,
                pageProps: props || ({}),
                showChrome: showChrome
            })
        }

        function onReplaceRequested(url, props, showChrome) {
            const nextKey = root.navigationKey(url, props, showChrome)
            if (stackView.depth === 0) {
                root.pendingNavigationKey = nextKey
                stackView.push(url, {
                    navigationUrl: url,
                    pageProps: props || ({}),
                    showChrome: showChrome
                })
                return
            }

            if (root.isCurrentPage(url, props, showChrome)
                    || root.pendingNavigationKey === nextKey)
                return

            root.pendingNavigationKey = nextKey
            stackView.replace(url, {
                navigationUrl: url,
                pageProps: props || ({}),
                showChrome: showChrome
            })
        }

        function onPopRequested() {
            if (stackView.depth > 1)
                stackView.pop()
        }
    }

    Connections {
        target: stackView.currentItem
        ignoreUnknownSignals: true
        function onCloseRequested() {
            NavigationController.pop()
        }
    }
}
