#include "platform_init.h"
#include "navigation_controller.h"

#include <QQuickWindow>

void onFirstFrame(QQuickWindow *window)
{
    Q_UNUSED(window)
}

// Non-Android platforms have no task-stack concept; minimising is a no-op.
// Android's implementation lives in android_back_handler.cpp.
void NavigationController::minimizeApp() {}
