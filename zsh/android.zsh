if [[ "${OSTYPE}" == darwin* ]]; then
    # https://github.com/ganeshrvel/openmtp
    # advanced android file transfer application
    _cask_install openmtp

    # https://developer.android.com/studio/releases/platform-tools.html
    # Android SDK Platform-Tools
    _cask_install android-platform-tools
fi

# adhere to xdg spec
export ANDROID_PREFS_ROOT="${XDG_CONFIG_HOME}"/android
export ADB_KEYS_PATH="${ANDROID_PREFS_ROOT}"
export ANDROID_EMULATOR_HOME="${XDG_DATA_HOME}"/android/emulator

# TODO: android sdk
# TODO: android studio
