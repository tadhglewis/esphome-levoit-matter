# Upstream status

This config needs two forks. Each change is meant to go upstream, after which the fork goes away. This page tracks where each one is.

Last checked 2026-11-25.

## Summary

| Fork | Upstream | Landed | In flight | Not sent |
|---|---|---|---|---|
| [tadhglewis/levoit](https://github.com/tadhglewis/levoit) | [tuct/levoit](https://github.com/tuct/levoit) | 2 | 3 | 0 |
| [tadhglewis/esphome-matter](https://github.com/tadhglewis/esphome-matter) | [DavidvtWout/esphome-matter](https://github.com/DavidvtWout/esphome-matter) | 0 | 1 | 8 |

The driver fork can go once [#142](https://github.com/tuct/levoit/pull/142) and [#143](https://github.com/tuct/levoit/pull/143) merge. The esphome-matter fork is the long one: nothing on the config's branch has been sent.

## tuct/levoit

The ESPHome driver for the purifier. Its maintainer reviews within hours and pushes fixes to contributors' branches.

| PR | What | State | Branch |
|---|---|---|---|
| [#140](https://github.com/tuct/levoit/pull/140) | Decode the Core 300S 19-byte status, `01 32 40`. Running speed in Auto. | Merged 2026-11-24 | [`fix/core300s-status-32-40`](https://github.com/tadhglewis/levoit/tree/fix/core300s-status-32-40) |
| [#141](https://github.com/tuct/levoit/pull/141) | Ask for the status after boot with `01 33 40`. The maintainer made it retry up to three times. | Merged 2026-11-24 | [`feat/core300s-status-request`](https://github.com/tadhglewis/levoit/tree/feat/core300s-status-request) |
| [#142](https://github.com/tuct/levoit/pull/142) | Panel filter reset (hold Sleep 3 s) on the Core 300S | Open, approved by the maintainer. Not run on hardware. | [`fix/core300s-panel-filter-reset`](https://github.com/tadhglewis/levoit/tree/fix/core300s-panel-filter-reset) |
| [#143](https://github.com/tuct/levoit/pull/143) | `power_button_held` binary sensor, for the 15-second reset | Open, approved by the maintainer before the rename. Frames seen; the sensor itself not confirmed. | [`feat/core-wifi-button-held`](https://github.com/tadhglewis/levoit/tree/feat/core-wifi-button-held) |
| [#144](https://github.com/tuct/levoit/pull/144) | Plasma: status offset 6 and command `01 E8 A5` (docs) | Open. Tested on the panel. | [`docs/core-plasma-command`](https://github.com/tadhglewis/levoit/tree/docs/core-plasma-command) |

This config builds from [`feat/core-wifi-button-hold`](https://github.com/tadhglewis/levoit/tree/feat/core-wifi-button-hold), which carries [#142](https://github.com/tuct/levoit/pull/142) and [#143](https://github.com/tuct/levoit/pull/143). When both merge, point the config at `tuct/levoit` `main` and drop the fork.

That branch was cut from the [#140](https://github.com/tuct/levoit/pull/140) and [#141](https://github.com/tuct/levoit/pull/141) branches before the maintainer's review commits, so it lacks the fixes listed under "Landed" below. Rebuild it from `tuct/levoit` `main` plus [#142](https://github.com/tuct/levoit/pull/142) and [#143](https://github.com/tuct/levoit/pull/143).

Hardware checks still owed: hold Sleep for 3 seconds ([#142](https://github.com/tuct/levoit/pull/142)), hold On/Off for 15 seconds ([#143](https://github.com/tuct/levoit/pull/143)).

### Landed

**[#140](https://github.com/tuct/levoit/pull/140), Core 300S 19-byte status.** Merged 2026-11-24 by tuct.

- Adds a decoder for `01 32 40`: the 18-byte layout with a byte inserted at offset 6. Display setting at offset 8, backlight at 7. In Auto it reports the running speed from offset 9.
- Capture with every panel state, both status requests and the auto mode command: [`devices/levoit-core300s/uart/status_32_40.txt`](https://github.com/tuct/levoit/blob/main/devices/levoit-core300s/uart/status_32_40.txt).
- Maintainer's review: "I checked the decoder against the frames". He pushed [95d43b9](https://github.com/tuct/levoit/commit/95d43b9): offset 9 is `0xFF` while the purifier is off, which was clamped to top speed when it was turned off in Auto, so offset 9 is used only while on. He took the panel filter reset back out ([e371a49](https://github.com/tuct/levoit/commit/e371a49)) to leave it to [#142](https://github.com/tuct/levoit/pull/142).
- Replaces: nothing on our side. Before it, a Core 300S on controller 1.0.0 showed no state at all on this driver.

**[#141](https://github.com/tuct/levoit/pull/141), status request at boot.** Merged 2026-11-24 by tuct.

- Sends `01 33 40`, the stock firmware's status query, when no status has been decoded after boot, and decodes the status from the ack. Units on `01 30 40` / `01 B0 40` are never sent it.
- Maintainer's review: he pushed [3cda1de](https://github.com/tuct/levoit/commit/3cda1de), asking at 3, 6 and 9 seconds instead of once at 3, because a lost frame or a slow MCU left the entities unknown for a minute.
- Replaces: up to a minute of unknown state after every restart.

Both branches are merged and can be deleted from the fork.

## DavidvtWout/esphome-matter

Matter support for ESPHome. Upstream has merged nothing since 2026-11-18, so the branch is still level with `main`.

### On the config's branch, [`ble-commissioning-fan-mapping`](https://github.com/tadhglewis/esphome-matter/tree/ble-commissioning-fan-mapping)

| Change | Not sent because | Next |
|---|---|---|
| Allow spaces in product and vendor names | It is someone else's open PR, [#112](https://github.com/DavidvtWout/esphome-matter/pull/112), cherry-picked | Drop when [#112](https://github.com/DavidvtWout/esphome-matter/pull/112) merges |
| Fix the `fan_control` auto feature name, and features on clusters without feature flags | Should move into the data model overrides first, and overlaps upstream [#94](https://github.com/DavidvtWout/esphome-matter/pull/94) | First PR |
| `matter.set_attribute` for code-driven clusters | Needs a test config | Second |
| Sensor rows for AirQuality and HEPA filter monitoring | Needs docs and a test config | Third |
| `fan_id`: map an ESPHome fan to FanControl | Needs docs and a test config | Fourth |
| `factory_partition`: read the setup code from a separate NVS partition made by `esp-matter-mfg-tool`, so the passcode is never on the device | Not run on hardware | Its own PR, after the fixes above |
| Bluetooth commissioning alongside `wifi` | Two linker wraps on the SDK; needs a design discussion in upstream issue [#97](https://github.com/DavidvtWout/esphome-matter/issues/97) | Last |
| Fixes from the first hardware run: HEPA DegradationDirection created before the condition feature, `ESP_ERR_NOT_FINISHED` treated as success, On and Toggle on On/Off, ug/m3 for PM | Found 2026-11-25 | Split into the PRs above they belong to. The first two are bugs anyone hits with a filter or a fan. |

All of it has now run on a Core 300S paired to Apple Home.

### Gaps, not started

| Gap | What it takes |
|---|---|
| Matter OTA Software Update | esphome-matter lists `ota_requestor` as an untested data-model device type, but leaves the SDK's `CONFIG_ENABLE_OTA_REQUESTOR` and `CONFIG_CHIP_OTA_IMAGE_BUILD` off, so nothing answers an OTA Provider and no `.ota` image is built. Turning them on gives a Matter-standard update path that Home Assistant and other controllers can drive, beside ESPHome's OTA. Two things to settle with upstream: who marks the new image valid (ESPHome's `safe_mode` does today, and the SDK never does), and refusing an update while the running image is unconfirmed. [levoit-matter](https://github.com/tadhglewis/levoit-matter/blob/main/docs/DESIGN.md#updates) does both. |

### Elsewhere in the fork

| Branch | What | State |
|---|---|---|
| [`thread-capable-check`](https://github.com/tadhglewis/esphome-matter/tree/thread-capable-check) | Only enable Matter over Thread on chips with an 802.15.4 radio | [#115](https://github.com/DavidvtWout/esphome-matter/pull/115), open since 2026-11-22, no maintainer response. Your own review asks whether OpenThread can supply the list instead of a copy. |
| [`thread-capability-gating`](https://github.com/tadhglewis/esphome-matter/tree/thread-capability-gating) | Earlier version of the same fix | Superseded by [`thread-capable-check`](https://github.com/tadhglewis/esphome-matter/tree/thread-capable-check) |
| `main` | Two Thread commits and a `WIP` | Unused. `main` should match upstream. |

The fork's other branches are copies of upstream's.

## What can be removed now

| Item | Where | Why |
|---|---|---|
| Branches [`fix/core300s-status-32-40`](https://github.com/tadhglewis/levoit/tree/fix/core300s-status-32-40) and [`feat/core300s-status-request`](https://github.com/tadhglewis/levoit/tree/feat/core300s-status-request) | tadhglewis/levoit | Merged as [#140](https://github.com/tuct/levoit/pull/140) and [#141](https://github.com/tuct/levoit/pull/141) |
| [`thread-capability-gating`](https://github.com/tadhglewis/esphome-matter/tree/thread-capability-gating), and the extra commits on `main` | tadhglewis/esphome-matter | Superseded, or WIP |
| Driver pointer in the HomeKit config | `levoit-core300s-homekit` | Done 2026-11-25. It only needs [#140](https://github.com/tuct/levoit/pull/140) and [#141](https://github.com/tuct/levoit/pull/141), now in `tuct/levoit` `main` |

Not yet: the driver fork for this config (waits on [#142](https://github.com/tuct/levoit/pull/142) and [#143](https://github.com/tuct/levoit/pull/143)), and the esphome-matter fork (nothing sent).
