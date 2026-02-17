#include "app_info.h"
#include <QString>

QString AppInfo::version() const
{
    return QStringLiteral(APP_VERSION_STRING);
}
