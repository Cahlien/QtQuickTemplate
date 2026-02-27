include_guard(GLOBAL)

# Fetch Spix UI testing framework via FetchContent.
# Spix requires AnyRPC; its FindAnyRPC.cmake expects AnyRPC::anyrpc,
# so we fetch anyrpc first and create the expected alias target.
# OVERRIDE_FIND_PACKAGE redirects Spix's find_package(AnyRPC) to the
# already-populated FetchContent, bypassing the Conan dependency provider.
#
# anyrpc v1.0.2 declares cmake_minimum_required(VERSION 2.8), which
# CMake 4+ rejects.  CMAKE_POLICY_VERSION_MINIMUM lets it configure
# under modern CMake without patching the vendored source.

# Capture this file's directory at parse time; inside the macro body
# CMAKE_CURRENT_LIST_DIR would resolve to the caller's directory.
set(_FETCH_SPIX_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}")

macro(fetch_spix)
    include(FetchContent)

    set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

    # PatchAnyrpcSanitizer.cmake fixes a logic bug in anyrpc v1.0.2:
    # `else(BUILD_WITH_ADDRESS_SANITIZE)` is a plain `else`, so ASan flags
    # are unconditionally added on non-MSVC/non-MINGW.  The patch rewrites
    # it to `elseif(BUILD_WITH_ADDRESS_SANITIZE)` so ASan is opt-in only.
    FetchContent_Declare(
        anyrpc
        GIT_REPOSITORY https://github.com/sgieseking/anyrpc.git
        GIT_TAG        v1.0.2
        EXCLUDE_FROM_ALL
        OVERRIDE_FIND_PACKAGE
        PATCH_COMMAND ${CMAKE_COMMAND} -P ${_FETCH_SPIX_CMAKE_DIR}/PatchAnyrpcSanitizer.cmake
    )
    set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(BUILD_WITH_LOG4CPLUS OFF CACHE BOOL "" FORCE)
    set(BUILD_WITH_ADDRESS_SANITIZE OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(anyrpc)

    # anyrpc's CMakeLists uses include_directories(${CMAKE_SOURCE_DIR}/include)
    # which resolves to the project root, not anyrpc's source tree.  Fix it.
    target_include_directories(anyrpc PUBLIC ${anyrpc_SOURCE_DIR}/include)

    # The project enables CMAKE_CXX_SCAN_FOR_MODULES globally; anyrpc is a
    # plain C++11 library that must not be scanned for C++20 module interfaces.
    set_target_properties(anyrpc PROPERTIES CXX_SCAN_FOR_MODULES OFF)

    if (NOT TARGET AnyRPC::anyrpc)
        add_library(AnyRPC::anyrpc ALIAS anyrpc)
    endif ()

    unset(CMAKE_POLICY_VERSION_MINIMUM)

    set(SPIX_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(SPIX_BUILD_TESTS    OFF CACHE BOOL "" FORCE)

    # PatchSpixInstall.cmake strips install()/export() rules from Spix's
    # lib/CMakeLists.txt — they fail because the anyrpc FetchContent target
    # cannot satisfy CMake's export-set validation requirements.
    FetchContent_Declare(
        spix
        GIT_REPOSITORY https://github.com/faaxm/spix.git
        GIT_TAG        v0.7
        EXCLUDE_FROM_ALL
        PATCH_COMMAND ${CMAKE_COMMAND} -P ${_FETCH_SPIX_CMAKE_DIR}/PatchSpixInstall.cmake
    )
    set(FETCHCONTENT_QUIET OFF)
    FetchContent_MakeAvailable(spix)
endmacro()
