import QtQuick
import QtQuick.Controls

Page {
    id: root

    property string navigationUrl: ""
    property bool showChrome: true

    // Runtime navigation state supplied by StackView push/replace.
    property var pageProps: ({})

    // Page-declared contract: key -> default value.
    property var requiredPageProps: ({})

    readonly property var resolvedPageProps: {
        const resolved = {}
        const required = root.requiredPageProps || {}
        const provided = root.pageProps || {}

        for (let key in required)
            resolved[key] = required[key]

        for (let key in provided)
            resolved[key] = provided[key]

        return resolved
    }

    function pageProp(name) {
        return root.resolvedPageProps[name]
    }
}
