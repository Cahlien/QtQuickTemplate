include_guard(GLOBAL)

set(QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM "" CACHE STRING
    "Apple Developer Team ID used for automatic release code signing"
)

set(QTQUICKTEMPLATE_APPLE_BUNDLE_IDENTIFIER "dev.crowell.app.template" CACHE STRING
    "Bundle identifier used for Apple platform code signing"
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
        XCODE_ATTRIBUTE_CODE_SIGN_STYLE[variant=Release] Automatic
        XCODE_ATTRIBUTE_DEVELOPMENT_TEAM[variant=Release] ${QTQUICKTEMPLATE_APPLE_DEVELOPMENT_TEAM}
        XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED[variant=Release] YES
        XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED[variant=Release] YES
    )

    if (IOS)
        set_target_properties(${target} PROPERTIES
            XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
            XCODE_ATTRIBUTE_PROVISIONING_PROFILE_SPECIFIER[variant=Release] ""
        )
    endif ()
endfunction()
