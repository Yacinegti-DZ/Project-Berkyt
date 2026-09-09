# Only enable on debug builds
if ! $DEBUG; then
    LOG "\033[0;33m! Non-debug build detected. Skipping\033[0m"
    return 0
fi

# Start adbd on boot
# https://android.googlesource.com/platform/packages/modules/adb/+/refs/heads/main/docs/dev/how_adbd_starts.md
for PARTITION in product odm odm_dlkm system_dlkm vendor vendor_dlkm; do
    USB_CONFIG="$(GET_PROP "$PARTITION" "persist.sys.usb.config")"
    if [ "$USB_CONFIG" ] && [[ ",$USB_CONFIG," != *",adb,"* ]]; then
        SET_PROP_IF_DIFF "$PARTITION" "persist.sys.usb.config" "$USB_CONFIG,adb"
    fi
done
unset PARTITION USB_CONFIG

# Disable adb authentication
# https://android.googlesource.com/platform/packages/modules/adb/+/refs/tags/android-15.0.0_r1/daemon/main.cpp#213
SET_PROP_IF_DIFF "system" "ro.adb.secure" "0"
SET_PROP_IF_DIFF "vendor" "ro.adb.secure" "0"

# Enable klogd daemon
# https://android.googlesource.com/platform/system/logging/+/refs/tags/android-16.0.0_r2/logd/main.cpp#214
SET_PROP "system" "ro.logd.kernel" "true"

# Do not filter out Samsung processes in logs
SET_PROP_IF_DIFF "system" "persist.log.semlevel" "0xFFFFFFFF"
