#!/bin/bash
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export MOCK_CALLS="$scratch/calls"
export MOCK_SAVED=1
export MOCK_CONNECTED=1
mkdir "$scratch/bin"
# Mock only the device APIs; run the real script and inspect its writes.
cat > "$scratch/bin/hidutil" <<'MOCK'
#!/bin/bash
if [ "$1" = list ]; then
  if [ "$MOCK_CONNECTED" = 1 ]; then
    echo '0x3554 0xfa07 0x0 1 6 0x123 Bluetooth Keyboard'
  fi
elif [ "${4:-}" = --set ]; then
  printf '%s\n' "$3 $5" >> "$MOCK_CALLS"
fi
MOCK
cat > "$scratch/bin/defaults" <<'MOCK'
#!/bin/bash
[ "$MOCK_SAVED" = 1 ]
MOCK
chmod +x "$scratch/bin/"*
export PATH="$scratch/bin:$PATH"
bash "$root/aula-f75-remap.sh" apply >/dev/null
grep -F '{"VendorID":13652,"ProductID":64007} {"UserKeyMapping":[]}' "$MOCK_CALLS" >/dev/null
grep -F '{"VendorID":9610,"ProductID":268} {"UserKeyMapping":[{' "$MOCK_CALLS" >/dev/null
export MOCK_SAVED=0
if bash "$root/aula-f75-remap.sh" apply >/dev/null 2>&1; then
  echo 'Expected missing saved preference to fail.' >&2; exit 1
fi
AULA_BLUETOOTH_MAPPING_OWNER=script bash "$root/aula-f75-remap.sh" apply >/dev/null
grep -F '{"VendorID":13652,"ProductID":64007} {"UserKeyMapping":[{' "$MOCK_CALLS" >/dev/null
export MOCK_CONNECTED=0
if bash "$root/aula-f75-remap.sh" apply >/dev/null 2>&1; then
  echo 'Expected disconnected keyboard to fail.' >&2; exit 1
fi
echo 'Mapping checks passed.'
