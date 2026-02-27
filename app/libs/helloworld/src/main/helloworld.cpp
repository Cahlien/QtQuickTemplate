#include "helloworld.h"

namespace dev::crowell::helloworld
{
    /*!
        \class HelloWorld
        \inmodule HelloWorld
        \brief A simple greeting class that provides a "Hello World" message.

        The HelloWorld class stores a greeting message and provides
        accessors for retrieving it in raw or formatted form.
    */

    /*!
        Constructs a HelloWorld object with the default message "Hello World".
    */
    HelloWorld::HelloWorld() : m_message("Hello World")
    {
    }

    /*!
        Returns the stored message as a string view.

        \return A \c std::string_view referencing the internal message string.
    */
    std::string_view HelloWorld::message() const noexcept
    {
        return m_message;
    }

    /*!
        Returns the message wrapped in a formatted string.

        The format is: \c{Message: '<message>'}.

        \return A \c std::string containing the formatted message.
    */
    std::string HelloWorld::formatMessage() const
    {
        return "Message: '" + m_message + "'";
    }
} // namespace dev::crowell::helloworld
