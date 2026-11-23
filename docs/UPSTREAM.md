# The esphome-matter branch

This config builds against `ble-commissioning-fan-mapping` in [tadhglewis/esphome-matter](https://github.com/tadhglewis/esphome-matter), a fork of [DavidvtWout/esphome-matter](https://github.com/DavidvtWout/esphome-matter). Nothing on the branch is Levoit-specific. The aim is for all of it to go upstream, after which this repo needs no local clone.

Everything here is compile-tested only. No PRs are open yet. They wait for a pass on real hardware.

## What the branch adds

One commit per future PR, on top of upstream `main`:

| Commit | What | Why it is needed |
|---|---|---|
| Allow spaces in product and vendor names | Cherry-pick of upstream PR #112 | A product name with a space broke the CMake build. |
| Fix the `fan_control` auto feature name, and features on clusters without feature flags | Codegen fix | The Auto feature could not be enabled from YAML. |
| Map sensors to AirQuality and HEPA filter monitoring attributes | New sensor rows | Lets an ESPHome sensor feed air quality level, filter percent and the change-filter flag. |
| Map ESPHome fans to the FanControl cluster with `fan_id` | New option on fan endpoints | Speed count and mode sequence are read once when the cluster is built, so they cannot be set from YAML afterwards. |
| Add BLE commissioning alongside the `wifi` component | New `ble_commissioning` option and a Wi-Fi driver | See below. |
| Make `matter.set_attribute` work for code-driven clusters | Generic fix | The action silently did nothing for fan control, air quality and filter monitoring. |

## Why Bluetooth commissioning needed a driver

Upstream compiles Bluetooth commissioning out whenever a config has `wifi:`. The underlying problem is that ESPHome and the Matter SDK each have their own Wi-Fi state machine and their own idea of where credentials are stored:

- ESPHome keeps credentials in its own preferences and tells the Wi-Fi driver to store nothing.
- The SDK's driver writes credentials to the Wi-Fi driver and assumes they persist. Credentials sent over Bluetooth would be gone after a reboot.
- Once the SDK connects, both stacks call connect and both read scan results.

The branch replaces the SDK's Wi-Fi driver with one that hands credentials to ESPHome's Wi-Fi component, the same way ESPHome's Improv component does, and lets ESPHome do the connecting and the saving. It hooks in with two linker wraps on the SDK's network commissioning setup. That is the part most likely to need redesign before upstream accepts it.

Constraints that come with it:

- Matter uses the NimBLE Bluetooth host and ESPHome's `esp32_ble` uses Bluedroid, so `bluetooth_proxy`, `esp32_ble_tracker` and `improv_ble` cannot be in the same build.
- ESPHome's `wifi` validation requires some provisioner, so the config includes `improv_serial`.
- A factory reset also erases ESPHome's saved Wi-Fi network.

## Plan for upstream

Upstream prefers core fixes before new device types, and a YAML package before a C++ mapping. So, smallest and least contentious first:

1. The feature codegen fix. Coordinate with upstream PR #94.
2. `matter.set_attribute` for code-driven clusters.
3. The sensor rows.
4. `fan_id`.
5. Bluetooth commissioning, after a design discussion in upstream issue #97.

Still to do before any of these are sent: docs and test configs for each piece, and moving the Auto feature name fix into the data model overrides where upstream keeps such fixes.
