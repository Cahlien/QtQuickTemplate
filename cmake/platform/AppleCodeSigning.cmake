include_guard(GLOBAL)

set(QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM "" CACHE STRING
    "Apple Developer Team ID used for automatic release code signing"
)

set(QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER "dev.crowell.qtquicktemplate" CACHE STRING
    "Bundle identifier used for Apple platform code signing"
)

set(QTQUICKTEMPLATE_IOS_PROVISIONING_PROFILE "" CACHE STRING
    "iOS provisioning profile name for App Store distribution (leave empty to let Xcode resolve automatically)"
)

set(QTQUICKTEMPLATE_MACOS_APP_SIGN_IDENTITY "" CACHE STRING
    "Explicit macOS app signing identity for release builds (for example: Developer ID Application: Example Corp (TEAMID))"
)

function(configure_apple_release_code_signing target)
    if (NOT APPLE OR NOT CMAKE_GENERATOR STREQUAL "Xcode")
        return()
    endif ()

    set_target_properties(${target} PROPERTIES
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER ${QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER}
    )

    if (IOS)
        if (NOT QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM)
            message(WARNING
                "QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM is not set; iOS release signing is disabled."
            )
            return()
        endif ()

        set_target_properties(${target} PROPERTIES
            XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ${QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM}
            XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED YES
            XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED YES
            XCODE_ATTRIBUTE_CODE_SIGN_STYLE Manual
            XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Apple Distribution"
            XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
        )

        if (QTQUICKTEMPLATE_IOS_PROVISIONING_PROFILE)
            set_target_properties(${target} PROPERTIES
                XCODE_ATTRIBUTE_PROVISIONING_PROFILE_SPECIFIER "${QTQUICKTEMPLATE_IOS_PROVISIONING_PROFILE}"
            )
        endif ()
    else ()
        set_target_properties(${target} PROPERTIES
            XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO
            XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED NO
        )
    endif ()
endfunction()
