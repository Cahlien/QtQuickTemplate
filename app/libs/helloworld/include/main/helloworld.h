#pragma once

#include <string>
#include <string_view>

#if defined(__APPLE__) && defined(TARGET_OS_IPHONE)
#  define HELLOWORLD_EXPORT
#else
#  include "helloworld_export.h"
#endif

namespace dev::crowell::helloworld
{
    class HELLOWORLD_EXPORT HelloWorld
    {
    public:
        HelloWorld();

        ~HelloWorld() = default;

        [[nodiscard]] std::string_view message() const noexcept;

        [[nodiscard]] std::string formatMessage() const;

    private:
        std::string m_message;
    };
} // namespace dev::crowell::helloworld
