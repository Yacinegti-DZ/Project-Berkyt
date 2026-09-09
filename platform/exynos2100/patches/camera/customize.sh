# Add ImageTagger lib
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libImageTagger.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Add Polarr libs
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/public.libraries-polarr.txt" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libPolarrSnap.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libYuv.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Add 360 lite libs
DELETE_FROM_WORK_DIR "system" "system/lib64/libdualcam_portraitlighting_gallery_360.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libdualcam_portraitlighting_gallery_360_lite.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Add Snap libs
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/public.libraries-snap.samsung.txt" 0 0 644 "u:object_r:system_file:s0"

# Add camera libs
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/public.libraries-arcsoft.txt" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFace_Landmark_Engine.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFacialStickerEngine.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFood.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
EVAL "echo \"libFood.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFoodDetector.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
EVAL "echo \"libFoodDetector.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libHpr_RecFace_dl_v1.0.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libLocalTM_pcc.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libfacialrestoration.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking_util.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libimage_enhancement.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsaiv_HprFace_cmh_support_jni.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
if [[ "$TARGET_CODENAME" == "p3s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsame_source_hdr.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi
EVAL "echo \"libsuperresolution_wrapper_v2.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
if [[ "$TARGET_CODENAME" == "p3s" ]]; then
    EVAL "echo \"libsuperresolutionraw_wrapper_v2.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
    EVAL "echo \"libuwsuperresolution_wrapper_v1.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
fi
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libveengine.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"

if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "36" ]; then
    # Upgrade midas blobs
    ADD_TO_WORK_DIR "r9sxxx" "vendor" "etc/midas/midas_config.json" 0 0 644 "u:object_r:vendor_configs_file:s0"
fi

if [[ "$TARGET_CODENAME" == "p3s" ]] && [ -f "$WORK_DIR/system/system/priv-app/AIOSKernelService/AIOSKernelService.apk" ]; then
    APPLY_PATCH "system" "system/priv-app/AIOSKernelService/AIOSKernelService.apk" \
        "$MODPATH/AIOSKernelService.apk/0001-Disable-Semantic-Search-T2T-adapter.patch"
fi

LOG "- Fixing MIDAS model detection"
EVAL "sed -i \"s/$TARGET_CODENAME/r0s/g\" \"$WORK_DIR/vendor/etc/midas/midas_config.json\""

LOG_STEP_IN "- Replacing camera blobs"
BLOBS_LIST="
system/lib64/libae_bracket_hdr.arcsoft.so
system/lib64/libarcsoft_dualcam_portraitlighting.so
system/lib64/libdualcam_refocus_gallery_48.so
system/lib64/libdualcam_refocus_gallery_59.so
system/lib64/libDualCamBokehCapture.camera.samsung.so
system/lib64/libface_recognition.arcsoft.so
system/lib64/libgallery_pic_best.arcsoft.so
system/lib64/libhybrid_high_dynamic_range.arcsoft.so
"
for blob in $BLOBS_LIST
do
    DELETE_FROM_WORK_DIR "system" "$blob" &
done

# shellcheck disable=SC2046
wait $(jobs -p) || exit 1

BLOBS_LIST="
system/lib64/libDocShadowRemoval.arcsoft.so
system/lib64/libeden_wrapper_system.so
system/lib64/libhigh_dynamic_range.arcsoft.so
system/lib64/libhigh_res.arcsoft.so
system/lib64/libImageSegmenter_v1.camera.samsung.so
system/lib64/liblow_light_hdr.arcsoft.so
system/lib64/libMultiFrameProcessing30.camera.samsung.so
system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so
system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so
system/lib64/libObjectDetector_v1.camera.samsung.so
system/lib64/libPortraitDistortionCorrectionCali.arcsoft.so
system/lib64/libSceneDetector_v1.camera.samsung.so
system/lib64/libsecuresnap_aidl.snap.samsung.so
system/lib64/libsnap_aidl.snap.samsung.so
system/lib64/libsuperresolution_wrapper_v2.camera.samsung.so
system/lib64/libsuperresolution.arcsoft.so
system/lib64/libSwIsp_core.camera.samsung.so
system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
system/lib64/libVideoClassifier.camera.samsung.so
"
if [[ "$TARGET_CODENAME" == "p3s" ]]; then
    BLOBS_LIST+="
    system/lib64/libsuperresolution_raw.arcsoft.so
    system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so
    system/lib64/libuwsuperresolution.arcsoft.so
    system/lib64/libuwsuperresolution_wrapper_v1.camera.samsung.so
    "
fi
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0" &
done

LOG_STEP_IN "- Fixing vendor display props"
# DPI
LCD_DENSITY="$(GET_PROP "vendor" "ro.sf.lcd_density")"
if [ "$LCD_DENSITY" ]; then
    SET_PROP "vendor" "ro.sf.init.lcd_density" "$LCD_DENSITY"
else
    ABORT "ro.sf.lcd_density prop not found in vendor"
fi
LOG_STEP_OUT
