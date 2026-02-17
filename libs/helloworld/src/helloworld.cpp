#include "helloworld.h"

HelloWorld::HelloWorld() : m_message("Hello World") {}

std::string_view HelloWorld::message() const noexcept
{
    return m_message;
}

std::string HelloWorld::formatMessage() const
{
    return "Message: '" + m_message + "'";
}
