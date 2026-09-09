LOG_STEP_IN "- Removing \"AI-generated content\" watermark from all image generation apps"

IMG_GEN_APPS="
system/app/SketchBook/SketchBook.apk
system/priv-app/DressRoom/DressRoom.apk
system/priv-app/PhotoEditor_AIFull/PhotoEditor_AIFull.apk
system/priv-app/SpriteWallpaper/SpriteWallpaper.apk
"

for APP in $IMG_GEN_APPS
do
    # Decode apks
    DECODE_APK "system" "$APP"
    
    LOG "- Removing watermark from $APP"
    
    # Replace AI-generated strings with a non-breaking space (U+00A0)
    find "$APKTOOL_DIR/$APP" -name "strings.xml" -exec perl -CSD -0777 -pi -e \
    's{(<string\b[^>]*name="[^"]*watermark_text[^"]*"[^>]*>)[^<]*(</string>)}{$1.chr(0xA0).$2}gse' {} +

    # Replace watermark drawables with sub-pixel (0.1px) vector placeholders
    find "$APKTOOL_DIR/$APP" -name "*watermark*.xml" \
    -exec sh -c 'cat > "$1" << "EOF"
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:height="0.1px"
    android:width="0.1px"
    android:viewportWidth="0.1"
    android:viewportHeight="0.1">
    <path
        android:fillColor="#00000000"
        android:pathData="M0,0h1v1h-1z" />
</vector>
EOF' _ {} \;
done

LOG_STEP_OUT

unset IMG_GEN_APPS