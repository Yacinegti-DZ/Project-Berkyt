# Disable app compaction
# S23 FE already ships DEFAULT_USE_COMPACTION = false and no isDebuggable field
if grep -q "DEFAULT_USE_COMPACTION:Z = true" \
        "$APKTOOL_DIR/system/framework/services.jar/smali/com/android/server/am/CachedAppOptimizer.smali" 2>/dev/null; then
    LOG "- Applying \"Disable app compaction\" to /system/system/framework/services.jar"
    APPLY_PATCH "system" "system/framework/services.jar" \
        "$MODPATH/appcompactor/services.jar/0001-Disable-app-compaction.patch"
fi

# Show battery regulatory info in Settings
# Requires SEM_BATTERY_PROPERTY_IC_AUTHENTICATION_RESULT support
if [ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_BATTERY_SUPPORT_BSOH_SETTINGS")" ]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_BATTERY_SUPPORT_BSOH_SETTINGS" --delete
fi
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_SETTINGS_ENABLE_EU_BATTERY_REGULATORY" "TRUE"
