# Upstream status

This config needs two forks. Each change is meant to go upstream, after which the fork goes away. This page tracks where each one is.

Last checked 2026-11-27.

## Summary

| Fork | Upstream | Landed | In flight | Not sent |
|---|---|---|---|---|
| [tadhglewis/levoit](https://github.com/tadhglewis/levoit) | [tuct/levoit](https://github.com/tuct/levoit) | 6 | 2 | 0 |
| [tadhglewis/esphome-matter](https://github.com/tadhglewis/esphome-matter) | [DavidvtWout/esphome-matter](https://github.com/DavidvtWout/esphome-matter) | 0 | 2 | 7 |

The driver fork is effectively done: everything the config needs has merged ([#142](https://github.com/tuct/levoit/pull/142), [#143](https://github.com/tuct/levoit/pull/143), [#144](https://github.com/tuct/levoit/pull/144), [#148](https://github.com/tuct/levoit/pull/148)), so the config can build from `tuct/levoit` `main`; [#149](https://github.com/tuct/levoit/pull/149) and [#151](https://github.com/tuct/levoit/pull/151) are open refinements. The esphome-matter fork is the long one: the first change is out as [#116](https://github.com/DavidvtWout/esphome-matter/pull/116); the rest of the config's branch is not yet sent.

## tuct/levoit

The ESPHome driver for the purifier. Its maintainer reviews within hours and pushes fixes to contributors' branches.

| PR | What | State | Branch |
|---|---|---|---|
| [#140](https://github.com/tuct/levoit/pull/140) | Decode the Core 300S 19-byte status, `01 32 40`. Running speed in Auto. | Merged 2026-11-24 | [`fix/core300s-status-32-40`](https://github.com/tadhglewis/levoit/tree/fix/core300s-status-32-40) |
| [#141](https://github.com/tuct/levoit/pull/141) | Ask for the status after boot with `01 33 40`. The maintainer made it retry up to three times. | Merged 2026-11-24 | [`feat/core300s-status-request`](https://github.com/tadhglewis/levoit/tree/feat/core300s-status-request) |
| [#142](https://github.com/tuct/levoit/pull/142) | Panel filter reset (hold Sleep 3 s) on the Core 300S | Merged 2026-11-24 | [`fix/core300s-panel-filter-reset`](https://github.com/tadhglewis/levoit/tree/fix/core300s-panel-filter-reset) |
| [#143](https://github.com/tuct/levoit/pull/143) | `power_button_held` binary sensor, for the 15-second reset | Merged 2026-11-24 | [`feat/core-wifi-button-held`](https://github.com/tadhglewis/levoit/tree/feat/core-wifi-button-held) |
| [#144](https://github.com/tuct/levoit/pull/144) | Plasma: status offset 6 and command `01 E8 A5` (docs) | Merged 2026-11-24 | [`docs/core-plasma-command`](https://github.com/tadhglewis/levoit/tree/docs/core-plasma-command) |
| [#148](https://github.com/tuct/levoit/pull/148) | Display reads off in Sleep and while off on the 19-byte status | Merged 2026-11-26 | [`fix/core-display-off-in-sleep`](https://github.com/tadhglewis/levoit/tree/fix/core-display-off-in-sleep) |
| [#149](https://github.com/tuct/levoit/pull/149) | Air quality while off: show it, or nothing? | Open, framed as a question for the maintainer | [`fix/core300s-no-air-reading-while-off`](https://github.com/tadhglewis/levoit/tree/fix/core300s-no-air-reading-while-off) |
| [#151](https://github.com/tuct/levoit/pull/151) | Speed reads 1 in Sleep on the 19-byte status | Open 2026-11-26. Re-applied after a conflict resolve dropped the change. | [`fix/core300s-sleep-running-speed`](https://github.com/tadhglewis/levoit/tree/fix/core300s-sleep-running-speed) |

Everything the config needs has merged, so point it at `tuct/levoit` `main` and drop the [`feat/core-wifi-button-hold`](https://github.com/tadhglewis/levoit/tree/feat/core-wifi-button-hold) fork branch. [#151](https://github.com/tuct/levoit/pull/151) (Sleep speed) is still open, so until it merges the fan shows the last manual speed in Sleep.

Hardware checks still owed on the merged PRs: hold Sleep for 3 seconds ([#142](https://github.com/tuct/levoit/pull/142)), hold On/Off for 15 seconds ([#143](https://github.com/tuct/levoit/pull/143)).

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

**[#142](https://github.com/tuct/levoit/pull/142), panel filter reset.** Merged 2026-11-24. Holding Sleep for 3 s (`01 E4 A5`, payload `00`) resets the filter count on the Core 300S, matching the stock firmware.

**[#143](https://github.com/tuct/levoit/pull/143), `power_button_held` sensor.** Merged 2026-11-24. Exposes the controller's held-On/Off report (`01 02 D1`) as a binary sensor on Core models, for the 15-second factory reset.

**[#144](https://github.com/tuct/levoit/pull/144), plasma docs.** Merged 2026-11-24. Documents status offset 6 and the plasma command `01 E8 A5` in LEVOIT_UART.md.

**[#148](https://github.com/tuct/levoit/pull/148), display off in Sleep.** Merged 2026-11-26. The display setting byte stays on in Sleep and while off, but the panel is dark; the component now reports Display off to match, keeping the stored setting.

These branches are merged and can be deleted from the fork.

## DavidvtWout/esphome-matter

Matter support for ESPHome. Upstream has merged nothing since 2026-11-18, so the branch is still level with `main`.

### On the config's branch, [`ble-commissioning-fan-mapping`](https://github.com/tadhglewis/esphome-matter/tree/ble-commissioning-fan-mapping)

| Change | Not sent because | Next |
|---|---|---|
| Allow spaces in product and vendor names | It is someone else's open PR, [#112](https://github.com/DavidvtWout/esphome-matter/pull/112), cherry-picked | Drop when [#112](https://github.com/DavidvtWout/esphome-matter/pull/112) merges |
| Fix the `fan_control` auto feature name | Open as [#116](https://github.com/DavidvtWout/esphome-matter/pull/116), 2026-11-27, with unit tests; closes [#91](https://github.com/DavidvtWout/esphome-matter/issues/91). Carved onto [`fix/fan-control-auto-feature-namespace`](https://github.com/tadhglewis/esphome-matter/tree/fix/fan-control-auto-feature-namespace), the namespace map only. | Drop when [#116](https://github.com/DavidvtWout/esphome-matter/pull/116) merges |
| Features on clusters without feature flags | A separate compile error (the config has no `feature_flags` member), and another contributor's open PR [#94](https://github.com/DavidvtWout/esphome-matter/pull/94) covers it | Support [#94](https://github.com/DavidvtWout/esphome-matter/pull/94); drop ours when it merges |
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
| The merged PR branches: `fix/core300s-status-32-40`, `feat/core300s-status-request`, `fix/core300s-panel-filter-reset`, `feat/core-wifi-button-held`, `docs/core-plasma-command`, `fix/core-display-off-in-sleep` | tadhglewis/levoit | Merged as [#140](https://github.com/tuct/levoit/pull/140)–[#144](https://github.com/tuct/levoit/pull/144) and [#148](https://github.com/tuct/levoit/pull/148) |
| [`thread-capability-gating`](https://github.com/tadhglewis/esphome-matter/tree/thread-capability-gating), and the extra commits on `main` | tadhglewis/esphome-matter | Superseded, or WIP |
| Driver pointer in the HomeKit config | `levoit-core300s-homekit` | Done 2026-11-25. It only needs [#140](https://github.com/tuct/levoit/pull/140) and [#141](https://github.com/tuct/levoit/pull/141), now in `tuct/levoit` `main` |

Not yet: the esphome-matter fork (most of the config's branch is unsent). The driver fork's blockers have all merged; [#149](https://github.com/tuct/levoit/pull/149) and [#151](https://github.com/tuct/levoit/pull/151) are open refinements.
