# Fix anyrpc v1.0.2 CMake logic bug: `else(BUILD_WITH_ADDRESS_SANITIZE)` is
# parsed as a plain `else`, unconditionally adding -fsanitize=address on
# non-MSVC/non-MINGW platforms.  Replace the broken else with a proper
# elseif so ASan is only enabled when BUILD_WITH_ADDRESS_SANITIZE is ON.

file(READ "CMakeLists.txt" _content)
string(REPLACE
    "else (BUILD_WITH_ADDRESS_SANITIZE)"
    "elseif (BUILD_WITH_ADDRESS_SANITIZE)"
    _content "${_content}")
file(WRITE "CMakeLists.txt" "${_content}")
