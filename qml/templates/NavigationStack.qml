import QtQuick
import QtQuick.Controls

Item {
    id: root

    property bool displayedShowChrome: true

    function syncNavigationState() {
        if (!stackView.currentItem)
            return

        const currentItem = stackView.currentItem
        const currentShowChrome = typeof currentItem.showChrome === "boolean"
                                ? currentItem.showChrome
                                : true

        displayedShowChrome = currentShowChrome
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

    Item {
        id: iosBackSwipeLayer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: edgeWidth
        z: 100
        visible: Qt.platform.os === "ios" && stackView.depth > 1

        property real edgeWidth: Math.max(20, Math.min(parent.width * 0.08, 40))
        property real triggerDistance: Math.max(56, Math.min(parent.width * 0.22, 120))
        property real maxVerticalDrift: 64
        property bool tracking: false
        property bool canceled: false
        property real dragX: 0

        DragHandler {
            target: null
            acceptedDevices: PointerDevice.TouchScreen
            xAxis.enabled: true
            yAxis.enabled: true

            onActiveChanged: {
                if (active) {
                    iosBackSwipeLayer.tracking = true
                    iosBackSwipeLayer.canceled = false
                    iosBackSwipeLayer.dragX = 0
                    return
                }

                if (!iosBackSwipeLayer.tracking)
                    return

                const shouldPop = !iosBackSwipeLayer.canceled
                             && iosBackSwipeLayer.dragX >= iosBackSwipeLayer.triggerDistance

                iosBackSwipeLayer.tracking = false
                if (shouldPop)
                    NavigationController.pop()
            }

            onTranslationChanged: {
                if (!iosBackSwipeLayer.tracking)
                    return

                if (Math.abs(activeTranslation.y) > iosBackSwipeLayer.maxVerticalDrift) {
                    iosBackSwipeLayer.canceled = true
                    return
                }

                iosBackSwipeLayer.dragX = activeTranslation.x
            }
        }
    }

    Item {
        id: iosForwardSwipeLayer
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: edgeWidth
        z: 100
        visible: Qt.platform.os === "ios" && NavigationController.canGoForward

        property real edgeWidth: Math.max(20, Math.min(parent.width * 0.08, 40))
        property real triggerDistance: Math.max(56, Math.min(parent.width * 0.22, 120))
        property real maxVerticalDrift: 64
        property bool tracking: false
        property bool canceled: false
        property real dragX: 0

        DragHandler {
            target: null
            acceptedDevices: PointerDevice.TouchScreen
            xAxis.enabled: true
            yAxis.enabled: true

            onActiveChanged: {
                if (active) {
                    iosForwardSwipeLayer.tracking = true
                    iosForwardSwipeLayer.canceled = false
                    iosForwardSwipeLayer.dragX = 0
                    return
                }

                if (!iosForwardSwipeLayer.tracking)
                    return

                const shouldForward = !iosForwardSwipeLayer.canceled
                                 && iosForwardSwipeLayer.dragX <= -iosForwardSwipeLayer.triggerDistance

                iosForwardSwipeLayer.tracking = false
                if (shouldForward)
                    NavigationController.forward()
            }

            onTranslationChanged: {
                if (!iosForwardSwipeLayer.tracking)
                    return

                if (Math.abs(activeTranslation.y) > iosForwardSwipeLayer.maxVerticalDrift) {
                    iosForwardSwipeLayer.canceled = true
                    return
                }

                iosForwardSwipeLayer.dragX = activeTranslation.x
            }
        }
    }

    Connections {
        target: NavigationController

        function onPushRequested(url, props, showChrome) {
            stackView.push(url, {
                navigationUrl: url,
                pageProps: props || ({}),
                showChrome: showChrome
            })
        }

        function onReplaceRequested(url, props, showChrome) {
            if (stackView.depth === 0) {
                stackView.push(url, {
                    navigationUrl: url,
                    pageProps: props || ({}),
                    showChrome: showChrome
                })
                return
            }

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
