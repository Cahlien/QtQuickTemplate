include_guard(GLOBAL)

set(QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM "" CACHE STRING
    "Apple Developer Team ID used for automatic release code signing"
)

set(QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER "dev.crowell.app.template" CACHE STRING
    "Bundle identifier used for Apple platform code signing"
)

set(QTQUICKTEMPLATE_MACOS_APP_SIGN_IDENTITY "" CACHE STRING
    "Explicit macOS app signing identity for release builds (for example: Developer ID Application: Example Corp (TEAMID))"
)

function(configure_apple_release_code_signing target)
    if (NOT APPLE OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    if (NOT QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM)
        message(WARNING
            "QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM is not set; release signing is disabled."
        )
        return()
    endif ()

    set_target_properties(${target} PROPERTIES
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER ${QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER}
        XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ${QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM}
        XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED YES
        XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED YES
    )

    if (IOS)
        set_target_properties(${target} PROPERTIES
            XCODE_ATTRIBUTE_CODE_SIGN_STYLE Automatic
            XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
            XCODE_ATTRIBUTE_PROVISIONING_PROFILE_SPECIFIER ""
        )
    else ()
        if (QTQUICKTEMPLATE_MACOS_APP_SIGN_IDENTITY)
            set_target_properties(${target} PROPERTIES
                XCODE_ATTRIBUTE_CODE_SIGN_STYLE "$<$<CONFIG:Release>:Manual>$<$<NOT:$<CONFIG:Release>>:Automatic>"
                XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "$<$<CONFIG:Release>:${QTQUICKTEMPLATE_MACOS_APP_SIGN_IDENTITY}>"
            )
        else ()
            message(WARNING
                "QTQUICKTEMPLATE_MACOS_APP_SIGN_IDENTITY is not set; macOS release signing will use Automatic style and may pick Apple Development."
            )
            set_target_properties(${target} PROPERTIES
                XCODE_ATTRIBUTE_CODE_SIGN_STYLE Automatic
            )
        endif ()
    endif ()
endfunction()
