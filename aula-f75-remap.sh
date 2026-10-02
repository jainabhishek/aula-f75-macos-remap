#!/bin/bash
set -u

BLE_MATCH='{"VendorID":13652,"ProductID":64007}'
USB_MATCH='{"VendorID":9610,"ProductID":268}'
SWAP='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x7000000E3,"HIDKeyboardModifierMappingDst":0x7000000E2},{"HIDKeyboardModifierMappingSrc":0x7000000E2,"HIDKeyboardModifierMappingDst":0x7000000E3},{"HIDKeyboardModifierMappingSrc":0x7000000E7,"HIDKeyboardModifierMappingDst":0x7000000E6},{"HIDKeyboardModifierMappingSrc":0x7000000E6,"HIDKeyboardModifierMappingDst":0x7000000E7}]}'
BLE_OWNER=${AULA_BLUETOOTH_MAPPING_OWNER:-macos}
case "$BLE_OWNER" in
  macos|script) ;;
  *) echo 'AULA_BLUETOOTH_MAPPING_OWNER must be macos or script.' >&2; exit 2 ;;
esac

registry_ids() {
  hidutil list --matching "$1" | awk '$4 == 1 && $5 == 6 && $6 ~ /^0x/ {print $6}' | sort -u
}

apply_mapping() {
  local match=$1 mapping=$SWAP
  if [ "$match" = "$BLE_MATCH" ] && [ "$BLE_OWNER" = macos ]; then
    if ! defaults read -g com.apple.keyboard.modifiermapping.13652-64007-0 >/dev/null 2>&1; then
      echo 'No saved Bluetooth modifier preference found. Configure macOS Modifier Keys first; see README.' >&2
      return 1
    fi
    mapping='{"UserKeyMapping":[]}'
  fi
  if hidutil property --matching "$match" --set "$mapping" >/dev/null; then
    echo "Applied mapping: $match (Bluetooth owner: $BLE_OWNER)"
  else
    echo "Failed to apply mapping: $match" >&2
    return 1
  fi
}

case "${1:-status}" in
  status)
    for match in "$BLE_MATCH" "$USB_MATCH"; do
      hidutil list --matching "$match"
      hidutil property --matching "$match" --get UserKeyMapping
    done
    ;;
  apply)
    connected=0
    result=0
    for match in "$BLE_MATCH" "$USB_MATCH"; do
      if [ -n "$(registry_ids "$match")" ]; then
        connected=1
        apply_mapping "$match" || result=1
      fi
    done
    if [ "$connected" = 0 ]; then
      echo 'No matching AULA keyboard detected.' >&2
      exit 1
    fi
    exit "$result"
    ;;
  watch)
    last_ble=''
    last_usb=''
    while true; do
      ble=$(registry_ids "$BLE_MATCH")
      usb=$(registry_ids "$USB_MATCH")
      if [ -n "$ble" ] && [ "$ble" != "$last_ble" ]; then
        if apply_mapping "$BLE_MATCH"; then last_ble=$ble; fi
      elif [ -z "$ble" ]; then last_ble=''; fi
      if [ -n "$usb" ] && [ "$usb" != "$last_usb" ]; then
        if apply_mapping "$USB_MATCH"; then last_usb=$usb; fi
      elif [ -z "$usb" ]; then last_usb=''; fi
      sleep 2
    done
    ;;
  *) echo "Usage: bash $0 {status|apply|watch}" >&2; exit 2 ;;
esac
