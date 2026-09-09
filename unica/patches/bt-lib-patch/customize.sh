if [ ! -f "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" ]; then
    LOG_STEP_IN "- Extracting libbluetooth_jni.so from com.android.bt.apex"

    if [ -d "$TMP_DIR" ]; then
        EVAL "rm -rf \"$TMP_DIR\""
    fi
    mkdir -p "$TMP_DIR"

    EVAL "unzip -j \"$WORK_DIR/system/system/apex/com.android.bt.apex\" \"apex_payload.img\" -d \"$TMP_DIR\""

    if command -v debugfs &> /dev/null; then
        EVAL "debugfs -R \"dump /lib64/libbluetooth_jni.so $TMP_DIR/libbluetooth_jni.so\" \"$TMP_DIR/apex_payload.img\""
        EVAL "cp -f \"$TMP_DIR/libbluetooth_jni.so\" \"$WORK_DIR/system/system/lib64/libbluetooth_jni.so\""
    else
        if ! sudo -n -v &> /dev/null; then
            LOG "\033[0;33m! Asking user for sudo password\033[0m"
            if ! sudo -v 2> /dev/null; then
                ABORT "Root permissions are required to unpack APEX image"
            fi
        fi

        mkdir -p "$TMP_DIR/tmp_out"
        EVAL "sudo mount -o ro \"$TMP_DIR/apex_payload.img\" \"$TMP_DIR/tmp_out\""
        EVAL "sudo cat \"$TMP_DIR/tmp_out/lib64/libbluetooth_jni.so\" > \"$WORK_DIR/system/system/lib64/libbluetooth_jni.so\""
        EVAL "sudo umount \"$TMP_DIR/tmp_out\""
    fi

    rm -rf "$TMP_DIR"

    SET_METADATA "system" "system/lib64/libbluetooth_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"

    LOG_STEP_OUT
fi

echo "===== BLUETOOTH DEBUG ====="
echo "File:"
ls -l "$WORK_DIR/system/system/lib64/libbluetooth_jni.so"
echo "SHA256:"
sha256sum "$WORK_DIR/system/system/lib64/libbluetooth_jni.so"

echo "Searching known signatures:"
for sig in \
    "39d9199428518152" \
    "2897773948050037" \
    "183a009048050037" \
    "88f6713948050037" \
    "2897663948050037" \
    "6872743908530037" \
    "76743948050037330080" \
    "97753948050037360080" \
    "97773948050037360080" \
    "3a009048050037330080" \
    "f6713948050037330080" \
    "f6733948050037330080" \
    "88d6743948050037"
do
    if xxd -p -c 0 "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" | grep -q "$sig"; then
        echo "[MATCH] $sig"
    fi
done
echo "==========================="
# Disable VaultKeeper support
# Before: [tbnz w8, #0, #0xXXXXXX]
# After: [b #0xXXXXXX]
if xxd -p -c 0 "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" | grep -q "39d9199428518152"; then
    HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
        "39d9199428518152" "000080d228518152"
elif xxd -p -c 0 "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" | grep -q "2897773948050037"; then
    HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
        "2897773948050037" "289777392a000014"
elif xxd -p -c 0 "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" | grep -q "183a009048050037"; then
    HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
        "183a009048050037" "183a00902a000014"
elif xxd -p -c 0 "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" | grep -q "88f6713948050037"; then
    HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
        "88f6713948050037" "88f671392a000014"
elif xxd -p -c 0 "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" | grep -q "2897663948050037"; then
    HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
        "2897663948050037" "289766392a000014"
elif xxd -p -c 0 "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" | grep -q "6872743908530037"; then
    HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
        "6872743908530037" "6872743998020014"
elif xxd -p -c 0 "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" | grep -q "76743948050037330080"; then
    HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
        "76743948050037330080" "7674392a000014330080"
elif xxd -p -c 0 "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" | grep -q "88d6743948050037"; then
    HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
        "88d6743948050037" "88d674392a000014"
else
    ABORT "No known patch available for the supplied libbluetooth_jni.so"
fi