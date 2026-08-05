#!/bin/sh
set -eu

case "${CI_XCODE_CLOUD:-}" in
    TRUE|true|1)
        defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
        defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
        ;;
esac
