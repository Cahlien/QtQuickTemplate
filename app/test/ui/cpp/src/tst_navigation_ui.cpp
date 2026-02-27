#include "tst_navigation_ui.h"

#include <Spix/Events/Identifiers.h>

#include <QDebug>
#include <chrono>
#include <exception>
#include <string>
#include <thread>

void tst_NavigationUI::waitForItem(const std::string &path, std::chrono::milliseconds timeout)
{
    using clock = std::chrono::steady_clock;
    const auto deadline = clock::now() + timeout;

    while (clock::now() < deadline)
    {
        if (existsAndVisible(spix::ItemPath(path)))
            return;
        std::this_thread::sleep_for(std::chrono::milliseconds{50});
    }

    qWarning() << "waitForItem timed out:" << QString::fromStdString(path);
}

std::string tst_NavigationUI::getNavigationUrl()
{
    return getStringProperty(spix::ItemPath("mainWindow"), "currentNavigationUrl");
}

void tst_NavigationUI::test_clickControlsTab_loadsStyleShowcase()
{
    qDebug() << "TEST: test_clickControlsTab_loadsStyleShowcase";

    waitForItem("mainWindow/controlsTab");
    mouseClick(spix::ItemPath("mainWindow/controlsTab"));
    std::this_thread::sleep_for(std::chrono::milliseconds{500});

    const std::string url = getNavigationUrl();
    if (url.find("StyleShowcase.qml") == std::string::npos)
    {
        qWarning() << "FAIL: expected URL to contain 'StyleShowcase.qml', got:"
                    << QString::fromStdString(url);
        ++m_failures;
    }
    else
    {
        qDebug() << "PASS: navigation URL contains 'StyleShowcase.qml'";
    }
}

void tst_NavigationUI::test_clickLicenseLink_loadsLicensePage()
{
    qDebug() << "TEST: test_clickLicenseLink_loadsLicensePage";

    waitForItem("mainWindow/licenseLinkArea");
    mouseClick(spix::ItemPath("mainWindow/licenseLinkArea"));
    std::this_thread::sleep_for(std::chrono::milliseconds{500});

    const std::string url = getNavigationUrl();
    if (url.find("License.qml") == std::string::npos)
    {
        qWarning() << "FAIL: expected URL to contain 'License.qml', got:"
                    << QString::fromStdString(url);
        ++m_failures;
    }
    else
    {
        qDebug() << "PASS: navigation URL contains 'License.qml'";
    }
}

void tst_NavigationUI::executeTest()
{
    try
    {
        // Wait for the UI to fully load
        std::this_thread::sleep_for(std::chrono::seconds{2});
        waitForItem("mainWindow");

        // Test 1: Click Controls tab
        test_clickControlsTab_loadsStyleShowcase();

        // Reset to Readme tab before next test
        waitForItem("mainWindow/readmeTab");
        mouseClick(spix::ItemPath("mainWindow/readmeTab"));
        std::this_thread::sleep_for(std::chrono::milliseconds{500});

        // Test 2: Click license link
        test_clickLicenseLink_loadsLicensePage();
    }
    catch (const std::exception &e)
    {
        qWarning() << "EXCEPTION in executeTest:" << e.what();
        ++m_failures;
    }

    quit();
}
