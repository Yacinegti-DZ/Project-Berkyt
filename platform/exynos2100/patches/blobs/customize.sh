LOG_STEP_IN "- Adding stock SoundBooster libs"
if [[ "$TARGET_CODENAME" == "r9s"  ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1070.so" 0 0 644 "u:object_r:system_lib_file:s0"
else
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1050.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SAG_EQ_ver2090.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundBooster_ver2090.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundAlive_play_plus_ver500.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundAlive_play_plus_ver900.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libaudiosaplus_sec_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding OK Google Hotword Enrollment blobs"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx6_WIDEBAND_LARGE"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentYGoogleEx6_WIDEBAND_LARGE"
ADD_TO_WORK_DIR "r9sxxx" "product" "priv-app/HotwordEnrollmentOKGoogleEx3CORTEXM4/HotwordEnrollmentOKGoogleEx3CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "r9sxxx" "product" "priv-app/HotwordEnrollmentXGoogleEx3CORTEXM4/HotwordEnrollmentXGoogleEx3CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

if [[ "$TARGET_CODENAME" == "r9s"  ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/init/rscmgr_s21fe.rc" 0 0 644 "u:object_r:system_file:s0"
fi

ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/android.hardware.sensor.hifi_sensors.xml" 0 0 644 "u:object_r:system_file:s0"
