#include "platform_init.h"

#include <QQuickWindow>

namespace dev::crowell::qtquicktemplate::platform
{
    void onFirstFrame(QQuickWindow *window)
    {
        Q_UNUSED(window)
    }
} // namespace dev::crowell::qtquicktemplate::platform
