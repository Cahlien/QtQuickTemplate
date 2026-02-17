#pragma once

#include <string>
#include <string_view>

#if defined(_WIN32) && defined(HELLOWORLD_SHARED)
#  if defined(HELLOWORLD_EXPORTS)
#    define HELLOWORLD_API __declspec(dllexport)
#  else
#    define HELLOWORLD_API __declspec(dllimport)
#  endif
#elif defined(__GNUC__) && defined(HELLOWORLD_SHARED)
#  define HELLOWORLD_API __attribute__((visibility("default")))
#else
#  define HELLOWORLD_API
#endif

class HELLOWORLD_API HelloWorld
{
public:
    HelloWorld();
    ~HelloWorld() = default;

    [[nodiscard]] std::string_view message() const noexcept;
    [[nodiscard]] std::string formatMessage() const;

private:
    std::string m_message;
};
