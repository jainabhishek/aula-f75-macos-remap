# AULA F75 macOS Remap

![Platform: macOS](https://img.shields.io/badge/platform-macOS-black)
![License: MIT](https://img.shields.io/badge/license-MIT-green)
[![Shell checks](https://github.com/jainabhishek/aula-f75-macos-remap/actions/workflows/check.yml/badge.svg)](https://github.com/jainabhishek/aula-f75-macos-remap/actions/workflows/check.yml)

Command and Option remapping for the AULA F75 on macOS, over Bluetooth and wired USB. Inspect the current mapping, apply it once, or run a lightweight watcher to handle reconnects.

Built with Bash and macOS's built-in `hidutil`. No third-party drivers or packages.

## Features

- Maps Alt to Command and Windows to Option, including right-side equivalents.
- Recognizes separate Bluetooth and wired USB identities.
- Lets macOS preferences or the script manage the Bluetooth mapping.
- Watches both connections independently, checking every two seconds.
- Reports unsuccessful mapping writes and retries them.
- Targets matching external keyboards rather than changing every keyboard.

## Get started

Requires macOS with `hidutil`, Bash, and a keyboard using one of the supported identities below. Normal use does not require administrator privileges. The swap assumes the keyboard sends Windows-style modifiers; check its hardware OS mode first.

```sh
git clone https://github.com/jainabhishek/aula-f75-macos-remap.git
cd aula-f75-macos-remap
bash aula-f75-remap.sh status
```

Choose how Bluetooth mapping should be managed:

| Mode | Setup | Behavior |
| --- | --- | --- |
| macOS-managed, default | Configure the Bluetooth keyboard's swap in macOS Modifier Keys | Clears the live Bluetooth mapping and relies on the saved preference |
| Script-managed | Restore default Bluetooth modifier settings in macOS | Applies the swap through `UserKeyMapping` |

For the default mode, open **System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys**, select the AULA keyboard, and configure Option as Command and Command as Option. Then run:

```sh
bash aula-f75-remap.sh apply
```

For script-managed Bluetooth, restore that keyboard's default modifier settings first, then run:

```sh
AULA_BLUETOOTH_MAPPING_OWNER=script bash aula-f75-remap.sh apply
```

Use only one layer for the Bluetooth swap. Applying it in both macOS preferences and the script can cancel the intended result. The default mode checks that a saved preference exists, but does not validate its contents.

Wired USB uses the script's live swap in either mode. Keep macOS Modifier Keys at their defaults for the USB identity.

## Commands

| Command | Action |
| --- | --- |
| `bash aula-f75-remap.sh status` | Show matching devices and live mappings; also the default without an argument |
| `bash aula-f75-remap.sh apply` | Apply the configuration to connected matching keyboards |
| `bash aula-f75-remap.sh watch` | Monitor connections and apply the configuration when registry IDs change |

Set `AULA_BLUETOOTH_MAPPING_OWNER=script` before `apply` or `watch` for script-managed Bluetooth. Stop the foreground watcher with Ctrl+C.

Verify shortcuts in an editable document: select text, then use Alt+C and Alt+V. A successful property write alone does not validate physical key behavior.

## Supported devices

| Connection | Product name | Vendor ID | Product ID |
| --- | --- | --- | --- |
| Bluetooth Low Energy | AULA-F75 5.0 KB | `13652` / `0x3554` | `64007` / `0xfa07` |
| Wired USB | Gaming Keyboard | `9610` / `0x258a` | `268` / `0x010c` |

Verify your device with `hidutil list`. Hardware revisions may use different IDs. The generic USB identity can match unrelated keyboards; disconnect them before applying or adapt the matching constants for your setup.

## Automatic startup

A per-user LaunchAgent can run `/bin/bash` with the absolute script path and the `watch` argument. Set `AULA_BLUETOOTH_MAPPING_OWNER` in its environment when using script-managed Bluetooth.

The utility does not install a background service automatically. Stop or update an existing remapping watcher before starting another copy.

## Removal

Stop the watcher, then clear the live mappings:

```sh
hidutil property --matching '{"VendorID":13652,"ProductID":64007}' --set '{"UserKeyMapping":[]}'
hidutil property --matching '{"VendorID":9610,"ProductID":268}' --set '{"UserKeyMapping":[]}'
```

Saved macOS Modifier Keys preferences are separate; restore their defaults in System Settings if needed.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| No keyboard detected | Connection mode and IDs in `hidutil list` |
| Unexpected Command/Option behavior | Hardware OS mode, macOS Modifier Keys, other remappers, and Bluetooth mapping owner |
| Missing saved preference error | Configure macOS Modifier Keys, or use script-managed mode with default macOS settings |
| Mapping disappears without reconnecting | Run `apply` again; the watcher reacts to registry ID changes |
| No output in a restricted environment | Run `status` from a normal macOS Terminal with access to HID services |

## Compatibility and limits

- Bluetooth mapping has been tested with physical shortcuts on an AULA F75.
- USB detection and mapping logic are implemented; wired physical shortcuts have not been validated for this release.
- Sleep, reconnect, and restart behavior still require physical-device testing.
- The watcher does not detect every mapping reset while a device remains connected.
- Saved modifier preference contents are not validated automatically.

## Development

```sh
bash -n aula-f75-remap.sh tests/check.sh
bash tests/check.sh
```

GitHub Actions runs syntax and mocked behavior checks for both device identities, mapping ownership, missing preferences, and disconnected devices. These checks do not simulate physical key presses.

## Author and license

Created by [Abhishek Jain](https://github.com/jainabhishek). Available under the [MIT License](LICENSE).

Independent project; not affiliated with AULA or Apple.

## Reference

[Apple Technical Note TN2450](https://developer.apple.com/library/archive/technotes/tn2450/_index.html) documents `hidutil`, `UserKeyMapping`, and HID usage values.

## Repository status

Public utility available to read, clone, and fork. Issues and pull requests are welcome; changes to this repository require maintainer approval.
