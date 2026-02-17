#include "app_info.h"
#include <QString>

/*!
    \class AppInfo
    \inmodule QtQuickTemplate
    \brief Singleton exposing application metadata to QML.

    AppInfo is registered as a QML singleton via \c QML_ELEMENT and
    \c QML_SINGLETON. It provides read-only properties such as
    \c version for display in the UI.
*/

/*!
    \property AppInfo::version
    The application version string, set at compile time from
    \c APP_VERSION_STRING.
*/
QString AppInfo::version() const
{
    return QStringLiteral(APP_VERSION_STRING);
}
