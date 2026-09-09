LOG_STEP_IN "- Fixing EDEN debug logging"

# Remove log.tag.EDEN=INFO from vendor/build.prop
VENDOR_BUILD_PROP="$WORK_DIR/vendor/build.prop"
if [ -f "$VENDOR_BUILD_PROP" ]; then
    LOG "- Removing \"log.tag.EDEN=INFO\" from vendor/build.prop"
    EVAL "sed -i '/^log\.tag\.EDEN=INFO$/d' \"$VENDOR_BUILD_PROP\""
fi

# Remove log.tag.EDEN=INFO from system/system/build.prop
SYSTEM_BUILD_PROP="$WORK_DIR/system/system/build.prop"
if [ -f "$SYSTEM_BUILD_PROP" ]; then
    LOG "- Removing \"log.tag.EDEN=INFO\" from system/system/build.prop"
    EVAL "sed -i '/^log\.tag\.EDEN=INFO$/d' \"$SYSTEM_BUILD_PROP\""
fi

LOG_STEP_OUT

LOG_STEP_IN "- Patching libvpl.so (64-bit only)"

LIBVPL_64="$WORK_DIR/vendor/lib64/libvpl.so"
PATCH_SCRIPT="$SRC_DIR/platform/exynos990/patches/eden/patch_libvpl_unload.py"

if [ -f "$LIBVPL_64" ] && [ -f "$PATCH_SCRIPT" ]; then
    LOG "- Patching vendor/lib64/libvpl.so (vplUnload → immediate return)"
    EVAL "python3 \"$PATCH_SCRIPT\" \"$LIBVPL_64\""
else
    if [ ! -f "$LIBVPL_64" ]; then
        LOG "- vendor/lib64/libvpl.so not found, skipping"
    fi
    if [ ! -f "$PATCH_SCRIPT" ]; then
        LOG "- patch_libvpl_unload.py not found, skipping"
    fi
fi

LOG_STEP_OUT
