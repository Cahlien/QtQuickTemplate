#pragma once

#include <Spix/TestServer.h>

#include <QString>
#include <chrono>
#include <string>

class tst_NavigationUI : public spix::TestServer
{
public:
    bool passed() const { return m_failures == 0; }

protected:
    void executeTest() override;

private:
    void waitForItem(const std::string &path, std::chrono::milliseconds timeout = std::chrono::milliseconds{5000});
    std::string getNavigationUrl();

    void test_clickControlsTab_loadsStyleShowcase();
    void test_clickLicenseLink_loadsLicensePage();

    int m_failures{0};
};
