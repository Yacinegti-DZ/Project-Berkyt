# UN1CA SELinux entries removal list
# - Append new type entries to the ENTRIES list
# - Add the EXACT type entry, DO NOT just add a common pattern (eg. "fabriccrypto", "fabriccrypto_exec" and NOT just "fabriccrypto")
# - DO NOT add the API version at the end of the entry (eg. "fabriccrypto" and NOT "fabriccrypto_30_0")
# - DO NOT add any parenthesis or statements (eg. "fabriccrypto" and NOT "expanttypeattribute ... (fabriccrypto)")
# - DO NOT add unnecessary types or remove the existing ones unless they aren't necessary anymore for all devices

# One UI 8.5 additions
ENTRIES+="
heatmap_default
heatmap_default_exec
sec_diag
sec_diag_exec
vendor_display_notch_prop
vendor_hal_systemhelper_hwservice
vendor_sys_qti_display
vendor_systemhelper_app
"

DUPLICATES+="
init.svc.vendor.wvkprov_server_hal
"

SERVICE_DUPLICATES+="
vendor.samsung.frameworks.codecsolution.ISehCodecSolution/default
"

# One UI 7.0 additions
ENTRIES+="
attiqi_app
attiqi_app_data_file
ker_app
kpp_app
kpp_data_file
"

# One UI 6.1.1 additions
ENTRIES+="
hal_dsms_default
hal_dsms_default_exec
proc_compaction_proactiveness
sbauth
sbauth_exec
"

# One UI 5.1.1 additions
ENTRIES+="
audiomirroring
audiomirroring_exec
audiomirroring_service
fabriccrypto
fabriccrypto_exec
fabriccrypto_data_file
hal_dsms_service
uwb_regulation_skip_prop
"

# [
GET_SYSTEM_EXT()
{
    if $TARGET_OS_BUILD_SYSTEM_EXT_PARTITION; then
        echo "system_ext"
    else
        echo "system/system/system_ext"
    fi
}

CIL_NAME="$(head -n 1 "$WORK_DIR/vendor/etc/selinux/plat_sepolicy_vers.txt")"
PATCHED=false
SELINUX_DIRS="
$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux
$WORK_DIR/product/etc/selinux
"

VENDOR_API_LIST="$(for d in $SELINUX_DIRS; do
                        [ -d "$d/mapping" ] || continue
                        find "$d/mapping" -type f -printf "%f\n"
                    done | sed '/.compat./d' | sed 's/.cil//' | sed 's/\./_/' | sort -u)"
# ]

for e in $ENTRIES; do
    # the problematic entry is not supported by the target device
    if ! grep -q -F "(type $e)" "$WORK_DIR/vendor/etc/selinux/plat_pub_versioned.cil"; then
        for d in $SELINUX_DIRS; do
            MAPPING_FILE="$d/mapping/$CIL_NAME.cil"
            [ -f "$MAPPING_FILE" ] || continue

            if ! grep -q -F "($e)" "$MAPPING_FILE" && \
                    ! grep -q -F "${e}_" "$MAPPING_FILE"; then
                continue
            fi

            PATCHED=true
            LOG "- \"$e\" SELinux entry not supported in ${d#$WORK_DIR/}. Removing"
            sed -i "/($e)/d" "$MAPPING_FILE"
            for a in $VENDOR_API_LIST; do
                sed -i "/${e}_${a}/d" "$MAPPING_FILE"
            done
        done

        for f in \
            "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/system_ext_sepolicy.cil" \
            "$WORK_DIR/product/etc/selinux/product_sepolicy.cil" \
            "$WORK_DIR/system/system/etc/selinux/plat_sepolicy.cil"; do
            [ -f "$f" ] || continue
            if grep -q "genfscon.*$e" "$f"; then
                PATCHED=true
                sed -i "/genfscon.*$e/d" "$f"
            fi
        done
    fi
done

_CLEAN_UNDECLARED_MAPPING_ATTRS()
{
    local MAPPING_FILE="$1"
    local ATTR_LIST
    local ATTR
    local ATTR_REGEX

    [ -f "$MAPPING_FILE" ] || return 0

    ATTR_LIST="$(mktemp)"
    { grep -o -E '[A-Za-z0-9_.+/@:-]+_([0-9]+_0|[0-9]{6})' "$MAPPING_FILE" || true; } | sort -u > "$ATTR_LIST"

    while read -r ATTR; do
        [ "$ATTR" ] || continue
        if grep -q -F "(typeattribute $ATTR)" "$MAPPING_FILE" || \
                grep -q -F "(typeattribute $ATTR)" "$WORK_DIR/vendor/etc/selinux/plat_pub_versioned.cil"; then
            continue
        fi

        ATTR_REGEX="$(sed 's/[][\/.^$*+?{}|()]/\\&/g' <<< "$ATTR")"
        PATCHED=true
        LOG "- \"$ATTR\" SELinux mapping attribute not declared by target vendor. Removing"
        sed -i "/$ATTR_REGEX/d" "$MAPPING_FILE"
    done < "$ATTR_LIST"

    rm -f "$ATTR_LIST"
}

for d in $SELINUX_DIRS; do
    _CLEAN_UNDECLARED_MAPPING_ATTRS "$d/mapping/$CIL_NAME.cil"
done

for e in $DUPLICATES; do
    if grep -q "^$e.*" "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/system_ext_property_contexts" 2> /dev/null; then
        # the problematic entry is currently present in system_ext, check if we need to remove it
        if grep -q "^$e.*" "$WORK_DIR/vendor/etc/selinux/vendor_property_contexts" 2> /dev/null; then
            PATCHED=true
            # the problematic entry is found in target vendor
            LOG "- \"$e\" SELinux duplicate entry found. Removing"
            sed -i "s/^$e/#SEC_DUPLICATE: $e/g" "$WORK_DIR/vendor/etc/selinux/vendor_property_contexts"
        fi
    fi
done

for e in $SERVICE_DUPLICATES; do
    if grep -q "^$e.*" "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/system_ext_service_contexts" 2> /dev/null; then
        # the problematic entry is currently present in system_ext, check if we need to remove it
        if grep -q "^$e.*" "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts" 2> /dev/null; then
            PATCHED=true
            # the problematic entry is found in target vendor
            LOG "- \"$e\" SELinux duplicate service found. Removing"
            sed -i "s|^$e|#SEC_DUPLICATE: $e|g" "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts"
        fi
    fi
done

LOG_STEP_IN "- Adding missing vendor service contexts"
_TYPE_EXISTS()
{
    grep -R -q -F "(type $1)" \
        "$WORK_DIR/system/system/etc/selinux" \
        "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux" \
        "$WORK_DIR/system_ext/etc/selinux" \
        "$WORK_DIR/system/system_ext/etc/selinux" \
        "$WORK_DIR/system/system/system_ext/etc/selinux" \
        "$WORK_DIR/product/etc/selinux" \
        "$WORK_DIR/vendor/etc/selinux" 2> /dev/null
}

_CIL_SYMBOL_EXISTS()
{
    _TYPE_EXISTS "$1" || \
        grep -R -q -F "(typeattribute $1)" \
            "$WORK_DIR/system/system/etc/selinux" \
            "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux" \
            "$WORK_DIR/system_ext/etc/selinux" \
            "$WORK_DIR/system/system_ext/etc/selinux" \
            "$WORK_DIR/system/system/system_ext/etc/selinux" \
            "$WORK_DIR/product/etc/selinux" \
            "$WORK_DIR/vendor/etc/selinux" 2> /dev/null
}

_APPEND_CONTEXT()
{
    local FILE="$1"
    local NAME="$2"
    local TYPE="$3"

    if [ ! -f "$FILE" ]; then
        LOGW "SELinux context file not found: ${FILE#$WORK_DIR/}"
        return 0
    fi

    if ! _TYPE_EXISTS "$TYPE"; then
        LOGW "SELinux type not found for $NAME: $TYPE"
        return 0
    fi

    if ! grep -q -F "$NAME" "$FILE"; then
        PATCHED=true
        LOG "- Adding $NAME -> $TYPE"
        printf "%-80s u:object_r:%s:s0\n" "$NAME" "$TYPE" >> "$FILE"
    fi
}

_APPEND_SEAPP_CONTEXT()
{
    local FILE="$1"
    local RULE="$2"

    [ -f "$FILE" ] || return 0

    if ! grep -q -F "$RULE" "$FILE"; then
        PATCHED=true
        LOG "- Adding SELinux app context: $RULE"
        printf "%s\n" "$RULE" >> "$FILE"
    fi
}

_APPEND_CONTEXT "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts" "vendor.samsung.hardware.security.vaultkeeper.ISehVaultKeeper/default" "VaultKeeper_service"
_APPEND_CONTEXT "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts" "vendor.samsung.hardware.security.hermes.ISehHermesCommand/default" "Hermes_service"
_APPEND_CONTEXT "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts" "vendor.samsung.hardware.sysinput.ISehSysInputDev/default" "SemInputDeviceManager_service"
_APPEND_CONTEXT "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts" "vendor.samsung.hardware.radio.bridge.ISehRadioBridge/slot1" "hal_radio_service"
_APPEND_CONTEXT "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts" "vendor.samsung.hardware.radio.bridge.ISehRadioBridge/slot2" "hal_radio_service"
_APPEND_CONTEXT "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts" "vendor.samsung.hardware.bluetooth.audio.ISehBluetoothAudioProviderFactory/default" "hal_audio_service"
_APPEND_CONTEXT "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts" "vendor.samsung.hardware.nfc_aidl.ISehNfc/default" "hal_nfc_service"
_APPEND_CONTEXT "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts" "android.hardware.security.keymint.IRemotelyProvisionedComponent/strongbox" "hal_remotelyprovisionedcomponent_service"
_APPEND_CONTEXT "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts" "vendor.qti.hardware.display.config.IDisplayConfig/default" "vendor_hal_displayconfig_service"
_APPEND_CONTEXT "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts" "vendor.qti.hardware.display.aiqe.IDisplayAiqe/default" "vendor_hal_displayconfig_service"
_APPEND_CONTEXT "$WORK_DIR/vendor/etc/selinux/vendor_hwservice_contexts" "vendor.display.config::IDisplayConfig" "hal_vendor_configstore_hwservice"
_APPEND_CONTEXT "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/system_ext_service_contexts" "vendor.samsung.hardware.kg30.ISehKg30/default" "knoxguard_service"
_APPEND_CONTEXT "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/system_ext_service_contexts" "vendor.samsung.hardware.khdm.ISehKhdm/default" "EDM_Policy_service"
_APPEND_CONTEXT "$WORK_DIR/system/system/etc/selinux/plat_service_contexts" "android.hardware.bluetooth.ranging.IBluetoothChannelSounding/samsung" "hal_bluetooth_service"

_APPEND_PROP_ALLOW()
{
    local FILE="$1"
    local DOMAIN="$2"
    local TYPE="$3"
    local RULE

    [ -f "$FILE" ] || return 0

    if ! _CIL_SYMBOL_EXISTS "$DOMAIN"; then
        LOGW "SELinux domain not found for property allow: $DOMAIN"
        return 0
    fi

    if ! _CIL_SYMBOL_EXISTS "$TYPE"; then
        LOGW "SELinux property type not found for $DOMAIN: $TYPE"
        return 0
    fi

    RULE="(allow $DOMAIN $TYPE (property_service (set)))"
    if ! grep -q -F "$RULE" "$FILE"; then
        PATCHED=true
        LOG "- Allowing $DOMAIN to set $TYPE"
        printf "%s\n" "$RULE" >> "$FILE"
    fi

    RULE="(allow $DOMAIN $TYPE (file (read getattr map open)))"
    if ! grep -q -F "$RULE" "$FILE"; then
        PATCHED=true
        printf "%s\n" "$RULE" >> "$FILE"
    fi
}

_APPEND_CIL_RULE()
{
    local FILE="$1"
    local RULE="$2"

    [ -f "$FILE" ] || return 0

    if ! grep -q -F "$RULE" "$FILE"; then
        PATCHED=true
        LOG "- Adding SELinux rule: $RULE"
        printf "%s\n" "$RULE" >> "$FILE"
    fi
}

_APPEND_SERVICE_FIND()
{
    local FILE="$1"
    local SOURCE="$2"
    local TARGET="$3"

    if ! _CIL_SYMBOL_EXISTS "$SOURCE"; then
        LOGW "SELinux domain not found for service allow: $SOURCE"
        return 0
    fi

    if ! _CIL_SYMBOL_EXISTS "$TARGET"; then
        LOGW "SELinux service type not found for $SOURCE: $TARGET"
        return 0
    fi

    _APPEND_CIL_RULE "$FILE" "(allow $SOURCE $TARGET (service_manager (find)))"
}

_APPEND_HWSERVICE_FIND()
{
    local FILE="$1"
    local SOURCE="$2"
    local TARGET="$3"

    if ! _CIL_SYMBOL_EXISTS "$SOURCE"; then
        LOGW "SELinux domain not found for hwservice allow: $SOURCE"
        return 0
    fi

    if ! _CIL_SYMBOL_EXISTS "$TARGET"; then
        LOGW "SELinux hwservice type not found for $SOURCE: $TARGET"
        return 0
    fi

    _APPEND_CIL_RULE "$FILE" "(allow $SOURCE $TARGET (hwservice_manager (find)))"
}

_APPEND_PROCESS_ALLOW()
{
    local FILE="$1"
    local SOURCE="$2"
    local TARGET="$3"
    local PERMS="$4"

    if ! _CIL_SYMBOL_EXISTS "$SOURCE"; then
        LOGW "SELinux domain not found for process allow: $SOURCE"
        return 0
    fi

    if [[ "$TARGET" != "self" ]] && ! _CIL_SYMBOL_EXISTS "$TARGET"; then
        LOGW "SELinux target not found for process allow: $TARGET"
        return 0
    fi

    _APPEND_CIL_RULE "$FILE" "(allow $SOURCE $TARGET (process ($PERMS)))"
}

SYSTEM_EXT_SEPOLICY="$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/system_ext_sepolicy.cil"
VENDOR_SEPOLICY="$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"
SYSTEM_EXT_SEAPP_RULE="user=oem_5959 seinfo=platform name=com.samsung.android.kgclient domain=kg_app type=app_data_file levelFrom=user"
for SYSTEM_EXT_SEAPP in \
    "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/system_ext_seapp_contexts" \
    "$WORK_DIR/system_ext/etc/selinux/system_ext_seapp_contexts" \
    "$WORK_DIR/system/system_ext/etc/selinux/system_ext_seapp_contexts" \
    "$WORK_DIR/system/system/system_ext/etc/selinux/system_ext_seapp_contexts"; do
    _APPEND_SEAPP_CONTEXT "$SYSTEM_EXT_SEAPP" "$SYSTEM_EXT_SEAPP_RULE"
done
_APPEND_PROP_ALLOW "$SYSTEM_EXT_SEPOLICY" "emservice" "vendor_em_tstate_prop"
_APPEND_PROP_ALLOW "$SYSTEM_EXT_SEPOLICY" "emservice" "em_version_prop"
_APPEND_PROP_ALLOW "$SYSTEM_EXT_SEPOLICY" "hermesd" "vendor_securehw_prop"
_APPEND_PROP_ALLOW "$SYSTEM_EXT_SEPOLICY" "hermesd" "vendor_securenvm_prop"
_APPEND_PROP_ALLOW "$SYSTEM_EXT_SEPOLICY" "snap_utility" "cache_status_prop"
_APPEND_PROP_ALLOW "$SYSTEM_EXT_SEPOLICY" "system_app" "logpersistd_logging_prop"
_APPEND_PROP_ALLOW "$VENDOR_SEPOLICY" "macloader" "vendor_default_prop_30_0"
_APPEND_SERVICE_FIND "$SYSTEM_EXT_SEPOLICY" "samsungpowersoundplay" "audio_service"
_APPEND_HWSERVICE_FIND "$VENDOR_SEPOLICY" "hal_audio_default" "system_suspend_hwservice_30_0"
_APPEND_PROCESS_ALLOW "$SYSTEM_EXT_SEPOLICY" "adbd" "self" "setcurrent"
_APPEND_PROCESS_ALLOW "$SYSTEM_EXT_SEPOLICY" "adbd" "su" "dyntransition"
_APPEND_PROCESS_ALLOW "$SYSTEM_EXT_SEPOLICY" "adbd" "adbd_tradeinmode" "dyntransition"

VENDOR_SEPOLICY="$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"
if _TYPE_EXISTS "heatmap_default" && _TYPE_EXISTS "app_efs_file"; then
    _APPEND_CIL_RULE "$VENDOR_SEPOLICY" "(allow heatmap_default app_efs_file (dir (search open read getattr)))"
    _APPEND_CIL_RULE "$VENDOR_SEPOLICY" "(allow heatmap_default app_efs_file (file (open read write getattr lock ioctl map)))"
fi
LOG_STEP_OUT

if ! $PATCHED; then
    LOG "\033[0;33m! Nothing to do\033[0m"
fi

unset ENTRIES DUPLICATES SERVICE_DUPLICATES CIL_NAME PATCHED SELINUX_DIRS VENDOR_API_LIST MAPPING_FILE SYSTEM_EXT_SEPOLICY VENDOR_SEPOLICY SYSTEM_EXT_SEAPP SYSTEM_EXT_SEAPP_RULE
unset -f GET_SYSTEM_EXT _CLEAN_UNDECLARED_MAPPING_ATTRS _TYPE_EXISTS _CIL_SYMBOL_EXISTS _APPEND_CONTEXT _APPEND_SEAPP_CONTEXT _APPEND_PROP_ALLOW _APPEND_CIL_RULE _APPEND_SERVICE_FIND _APPEND_HWSERVICE_FIND _APPEND_PROCESS_ALLOW
