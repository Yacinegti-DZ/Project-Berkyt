GET_FINGERPRINT_SENSOR_TYPE()
{
    if [[ "$1" == *"ultrasonic"* ]]; then
        echo "ultrasonic"
    elif [[ "$1" == *"optical"* ]]; then
        echo "optical"
    elif [[ "$1" == *"side"* ]]; then
        echo "side"
    else
        ABORT "Unknown fingerprint sensor type: \"$1\". Aborting"
    fi
}

if [[ "$SOURCE_FINGERPRINT_CONFIG_SENSOR" != "$TARGET_FINGERPRINT_CONFIG_SENSOR" ]]; then
    DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

    local FP_SMALI_FILES="
    system/framework/framework.jar/smali_classes6/com/samsung/android/bio/fingerprint/SemFingerprintManager.smali
    system/framework/framework.jar/smali_classes6/com/samsung/android/bio/fingerprint/SemFingerprintManager\$Characteristics.smali
    system/priv-app/SecSettings/SecSettings.apk/smali_classes5/com/samsung/android/settings/biometrics/fingerprint/FingerprintSettingsUtils.smali
    "
    for f in $FP_SMALI_FILES; do
        sed -i "s/$SOURCE_FINGERPRINT_CONFIG_SENSOR/$TARGET_FINGERPRINT_CONFIG_SENSOR/g" "$APKTOOL_DIR/$f"
    done

    if [[ "$(GET_FINGERPRINT_SENSOR_TYPE "$TARGET_FINGERPRINT_CONFIG_SENSOR")" == "ultrasonic" ]]; then
        DECODE_APK "system" "system/priv-app/BiometricSetting/BiometricSetting.apk"
        sed -i "s/$SOURCE_FINGERPRINT_CONFIG_SENSOR/$TARGET_FINGERPRINT_CONFIG_SENSOR/g" \
            "$APKTOOL_DIR/system/priv-app/BiometricSetting/BiometricSetting.apk/smali/com/samsung/android/biometrics/app/setting/DisplayStateManager.smali"

        local UTILS_CONFIG="$APKTOOL_DIR/system/priv-app/BiometricSetting/BiometricSetting.apk/smali/com/samsung/android/biometrics/app/setting/Utils\$Config.smali"
        local ULTRASONIC_LINE="$(grep -n 'sput-boolean.*FP_FEATURE_SENSOR_IS_ULTRASONIC:Z' "$UTILS_CONFIG" | tail -1)"
        local US_REG="$(sed 's/.*sput-boolean \(v[0-9]*\),.*/\1/' <<< "$ULTRASONIC_LINE")"
        local FP_STR_REG="v4"
        local CONTAINS_LINE="$(grep -B5 'FP_FEATURE_SENSOR_IS_ULTRASONIC:Z' "$UTILS_CONFIG" | grep 'invoke-virtual.*contains')"
        if [[ "$CONTAINS_LINE" =~ \{(v[0-9]+),\ *(v[0-9]+)\} ]]; then
            FP_STR_REG="${BASH_REMATCH[1]}"
        fi
        sed -i "s|sput-boolean .*FP_FEATURE_SENSOR_IS_OPTICAL:Z|const-string $US_REG, \"optical\"\n\n    invoke-virtual {$FP_STR_REG, $US_REG}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z\n\n    move-result $US_REG\n\n    sput-boolean $US_REG, Lcom/samsung/android/biometrics/app/setting/Utils\$Config;->FP_FEATURE_SENSOR_IS_OPTICAL:Z|" "$UTILS_CONFIG"

        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_LOCAL_HBM" "0"
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_BIOAUTH_CONFIG_FINGERPRINT_FEATURES" "ultrasonic_display_phone"
    fi
fi

unset -f GET_FINGERPRINT_SENSOR_TYPE
