# Strip install() and export() rules from Spix's lib/CMakeLists.txt.
# Spix is consumed as a FetchContent build-time dependency; its install and
# export rules fail because the anyrpc target (also FetchContent) is not in
# an export set and has non-relocatable include paths.

file(READ "lib/CMakeLists.txt" _content)
string(REGEX REPLACE "install[ \t]*\\([^)]+\\)" "" _content "${_content}")
string(REGEX REPLACE "export[ \t]*\\([^)]+\\)" "" _content "${_content}")
file(WRITE "lib/CMakeLists.txt" "${_content}")
