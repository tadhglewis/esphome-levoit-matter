# Levoit Core 300S on Matter: implementation plan

Researched 2026-11-23. Target is Apple Home on iOS 27 and tvOS 27 with an Apple TV as home hub.

## Goal

Local-only firmware for the Levoit Core 300S that:

1. Speaks Matter over Wi-Fi and commissions the way a retail device does. Scan a QR code, the phone hands over Wi-Fi credentials over BLE, and a reset returns it to that state.
2. Exposes manual speed, auto, sleep, display, child lock, filter life and air quality. Other Levoit models should need only a config change.
3. Takes firmware updates over the air.

## Status

Updated 2026-11-23, after the first implementation pass. Compile-tested only. Nothing has run on hardware.

| Phase | State |
|---|---|
| 0 Bench setup | ESPHome 2026.11.0 in `.venv`. Fork cloned to `esphome-matter/`, branch `ble-commissioning-fan-mapping`. No dev board yet. |
| 1 Open, back up, plain ESPHome | Not started. Hardware arrives 2026-11-24. |
| 2 Fit spike | Flash answered: 1.46 MB in a 1.94 MB slot with BLE. Heap during pairing still unmeasured. Static DRAM is 103.6 KB of 124.6 KB once Bluetooth reserves its share. |
| 3 Apple Home bench test | Not started. |
| 4 Purifier mapping | Written. `fan_id` in C++, filter and air quality as sensor table rows, switches in YAML. |
| 5 BLE commissioning | Written. Untested. |
| 6 Reset, LED | Reset gesture written in YAML. Wi-Fi LED untouched. |
| 7 OTA | ESPHome OTA configured. Untested. |
| 8 Upstream | Five commits on `ble-commissioning-fan-mapping` in tadhglewis/esphome-matter, split by future PR. No PRs opened. |

What changed from the original design:

- **Switches use the generic path.** Sleep, Display and Child Lock are `on_off_plug_in_unit` endpoints wired with `on_attribute` and `matter.set_attribute` in YAML. No `switch_id` in the fork.
- **Filter and air quality are sensor table rows.** Keys are `hepa_filter_condition`, `hepa_filter_change_indication` and `air_quality`. The filter reset command is not exposed.
- **Fan features are declared, not inferred.** `with_features: [multi_speed, auto]` in YAML. `configure_fan_control` only sets SpeedMax and FanModeSequence from the fan's traits and warns on a mismatch.
- **The driver hook is a linker wrap** of `ESPMatterNetworkCommissioningClusterServerInitCallback`. No esp-matter fork change yet.
- **`improv_serial` is in the device config** because ESPHome rejects `wifi:` with no network unless a provisioner is present.
- **The lock is called "Child Lock" here.** Levoit's manual calls the same function Display Lock. The name follows the levoit component's `type: child_lock`.

The working config is `levoit-core300s.yaml`. Build and flash steps are in `README.md`.

### Upstream fit, 2026-11-23

Checked against upstream's `CONTRIBUTING.md`, issue #24, the lights docs and the maintainer's reviews on PRs #53 and #86.

- Upstream wants core mechanisms fixed before device types, and a YAML package in `packages/` before a C++ mapping. Device type PRs merge slowly.
- `on_attribute` already fires when a controller writes a code-driven cluster such as FanControl. `matter.set_attribute` did not reach those clusters. That was the real generic gap.
- The fork now fixes it for fan control, air quality and filter monitoring, and the sensor updaters use the same setter table. Compile-tested.
- `ble-commissioning-fan-mapping` is the single branch the firmware builds from: the #112 cherry-pick plus five commits, formatted with `ruff` and `clang-format`. Each commit becomes its own PR branch, rebased onto upstream `main`, when it is sent.

Proposed PR order once hardware testing passes: feature fixes (coordinate with #94), `set_attribute` for code-driven clusters, sensor rows, fan and air purifier packages, `fan_id`, then BLE commissioning after a design discussion in #97.

Deferred:

- **`packages/fan.yaml` and `packages/air-purifier.yaml`.** They need a generic way to set a cluster's initial attribute values, because SpeedMax and FanModeSequence are read once when the cluster is built. `fan_id` does this in C++ today.
- **The `auto` to `fan_auto` name fix belongs in `data_model/overrides`.** That needs the zap converter rerun against the Matter data model sources.
- **Docs and test configs** for every piece.

### Review, 2026-11-23

An independent review of the fork diff found no crashes or data races. Eight findings were fixed: restoring the previous network after a failed or reverted connect, dropping the link on revert to no network, ending empty scans without a 12 second wait, wrapping the cluster shutdown callback, the Sleep switch off action, the boot replay of persisted switch state, and the reset gesture counting toggles that came from Matter.

Known limitations left in place:

- **Sleep shows as the last manual speed.** The levoit fan keeps its last manual level while in Sleep, so Matter shows that level. Writing the same level from Home does not leave Sleep. Use the Sleep switch or pick a different speed.
- **A full Matter event queue can strand a connect or scan callback.** The result of `ScheduleLambda` is not checked.
- **RemoveNetwork followed by commit does not clear saved credentials.** Factory reset does.
- **Every secured network is reported as WPA2-Personal** in scan results.
- **`air_quality` expects a 1 to 6 level**, which is what the Levoit MCU reports. A 0 to 500 AQI sensor needs a template sensor in front.
- **Persisted switch state is ignored for 15 seconds after boot** so the purifier's own state wins. This is done in the device YAML.

### Levoit's own pairing and reset, from the Core 300S manual

- Display Off and Display Lock are two separate buttons. Display Off is a tap. Display Lock is a 3 second hold.
- Press and hold On/Off to configure Wi-Fi. The manual defers to the VeSync app for the duration.
- Press and hold On/Off for 15 seconds, until the Wi-Fi indicator turns off, to restore defaults and disconnect from the VeSync app.
- Press and hold Sleep for 3 seconds to reset the Check Filter indicator. The MCU reports this to the ESP as `01 E4 A5`, and tuct/levoit already handles it.

No community firmware documents the frame the MCU sends for the On/Off hold. tuct/levoit, mulcmu and acvigue all drive the Wi-Fi LED but none decode a pairing or reset request. Find it on day one by logging unknown frames while holding On/Off for 5 and 15 seconds. If it exists, bind it to `matter.factory_reset` and drop the display-toggle gesture.

## Decisions

| Decision | Choice | Why |
|---|---|---|
| Stack | ESPHome + [esphome-matter](https://github.com/DavidvtWout/esphome-matter) + [tuct/levoit](https://github.com/tuct/levoit) | Reuses the levoit UART protocol for ten models and ESPHome's OTA. Pure esp-matter would mean rewriting both. |
| Not HAP-ESPHome | Ruled out | Matter is controller-agnostic. Cost: HomeKit has native child lock and filter maintenance characteristics that Apple's Matter mapping lacks. |
| Hardware | Stock ESP32-SOLO-1C if it fits, XIAO ESP32-C6 if not | Decided by measurement in phase 2. |
| First flash | Open the unit and solder | Allows a full backup and a custom partition table. |
| OTA | ESPHome native OTA, pushed from a Mac | Apple Home will not serve updates to an uncertified device without DCL TestNet setup. |
| Controllers | Apple Home only | Drop `api`, `web_server` and `captive_portal` to save flash and RAM. |
| Upstreaming | Work in forks, send PRs as pieces settle | Speed first. |

## Findings

### Why BLE commissioning is "broken" in esphome-matter

1. **Compiled out by design.** `components/matter/__init__.py:237-278` computes `has_connectivity = use_openthread or use_wifi` and sets `CONFIG_ENABLE_CHIPOBLE` to its inverse. Any config with `wifi:` has no BLE.
2. **The no-`wifi:` path forces OpenThread on.** It cannot build for chips without an 802.15.4 radio. PR #115 addresses this. On that path ESPHome also has no network interface, so `api` and `ota` never come up.
3. **Two owners of Wi-Fi credentials.** ESPHome calls `esp_wifi_set_storage(WIFI_STORAGE_RAM)` in `wifi_component_esp_idf.cpp` and keeps credentials in its own preference through `save_wifi_sta`. connectedhomeip's `ESPWiFiDriver` writes them with `esp_wifi_set_config` and assumes the driver persists them. Credentials commissioned over BLE would be gone after a reboot.
4. **Connecting cancels the existing wrap.** `matter_wifi_stack.cpp` wraps `ConnectivityManagerImpl::InitWiFi` to set `kWiFiStationMode_ApplicationControlled`. `ESPWiFiDriver::ConnectWiFiNetwork` then sets the mode to Disabled and back to Enabled, after which connectedhomeip's `DriveStationState` calls `esp_wifi_connect` alongside ESPHome's state machine.
5. **Scan results race.** Both stacks register `WIFI_EVENT` handlers. ESPHome reads and clears the AP list on `WIFI_EVENT_SCAN_DONE`, so a Matter `ScanNetworks` can come back empty.
6. **ESPHome requires a provisioner.** `wifi` validation fails without an SSID, an AP, DPP or Improv. A fallback AP changes the Wi-Fi mode after `ap_timeout`, which would break a commissioning in progress.
7. **Different BLE hosts.** Matter uses NimBLE. ESPHome's `esp32_ble` uses Bluedroid. `improv_ble`, `esp32_ble_tracker` and `bluetooth_proxy` cannot be in the same build.
8. **QR payload names one transport.** `generate_commissioning_codes_` sets `kOnNetwork` or `kBLE` by ifdef.
9. **Reboot timers.** `wifi.reboot_timeout` defaults to 15 minutes and would reboot an unprovisioned device.

What already works in our favour:

- `CONFIG_USE_BLE_ONLY_FOR_COMMISSIONING` makes esp-matter call `BLEMgr().Shutdown()` once a fabric exists.
- `improv_ble_component.cpp` shows the exact ESPHome calls a provisioner needs: `set_sta`, `start_connecting`, `save_wifi_sta` on success, `clear_sta` on failure.
- ESPHome has `WiFiConnectStateListener` and `WiFiScanResultsListener` interfaces, requested from Python with `request_wifi_connect_state_listener()` and `request_wifi_scan_results_listener()`.

### Where the driver plugs in

esp-matter creates the cluster with a hardwired driver at `components/esp_matter/data_model_provider/clusters/network_commissioning/integration.cpp:138`:

```cpp
gServers[index].Create(endpointId, &(DeviceLayer::NetworkCommissioning::ESPWiFiDriver::GetInstance()), ...);
```

`-Wl,--wrap` cannot intercept `ESPWiFiDriver`'s virtual methods because the vtable is in the same translation unit as the definitions. Two options:

- **A, no fork change.** Wrap the free function `ESPMatterNetworkCommissioningClusterServerInitCallback` and construct `NetworkCommissioningCluster` with our own driver. About 40 lines copied from the integration file.
- **B, upstreamable.** Add a setter to the `davidvtwout/esp_matter` fork so the application supplies the `WiFiDriver`. The same patch can let the app set `ApplicationControlled` before start, which removes the existing `InitWiFi` wrap.

Start with A. Move to B when it works.

### Other gaps in esphome-matter

- **No fan mapping.** Lights have `light_id`. Fans can only be driven with raw `on_attribute` and `set_attribute`. Issues #90, #91, #92 and PR #94 show `fan_control` features such as `auto` do not generate valid C++ yet.
- **No filter mapping.** HEPA Filter Monitoring is available as a bare cluster. In esp-matter it is under `resource_monitor` and may need a delegate.
- **Air quality mapping exists.** `air_quality_sensor` with `pm_2_5:` already maps an ESPHome sensor. The AirQuality enum needs checking.
- **Factory reset is partial.** `MatterComponent::factory_reset` erases `chip-config`, `chip-counters` and `CHIP_KVS`. Wi-Fi credentials stay.
- **No Matter OTA.** Issue #69. ESPHome OTA is confirmed working in issue #54.
- **Classic ESP32 untested.** README lists C3, C5, C6, S3, H2.
- **Reconnect after restart can take up to a minute.** Stated in the README.

### Hardware

- Module is ESP32-SOLO-1C on `CORE300S Ctrl Board V1.4.1`. Single core, so `CONFIG_FREERTOS_UNICORE: y` is mandatory. UART to the MCU is GPIO16 RX, GPIO17 TX, 115200 baud.
- Secure boot is off and firmware is unsigned, per [nico202's protocol notes](https://github.com/nico202/levoit-core300s-ota-wifi-flash/blob/main/docs/protocol.md).
- Flash size is assumed 4 MB. Confirmed only for a Vital 200S Pro dump.
- ESPHome's default 4 MB ESP-IDF layout gives 0x1C0000, 1.75 MB, per OTA slot with a 448 KB NVS.
- [esp-matter's light example layout](https://github.com/espressif/esp-matter/blob/main/examples/light/partitions.csv) gives 0x1E0000, 1.92 MB, per slot with a 48 KB NVS.
- ESPHome accepts a custom table through `esp32: partitions:`.
- [Espressif's measurements](https://docs.espressif.com/projects/esp-matter/en/latest/esp32/optimizations.html) for the light example on a C3: 1.41 MB flash, 36 KB free heap at boot with BLE up, 101 KB after commissioning.
- Estimate for ESPHome + Matter + NimBLE on the classic chip: 1.8 to 2.2 MB. This is a guess until phase 2.

### Apple Home behaviour

Apple documents no cluster-level mapping for purifiers. Evidence is Apple DTS forum replies, the connectedhomeip Darwin guide and user reports.

- Air Purifier 0x002D, Fan 0x002B and Air Quality Sensor 0x002C are supported since iOS 18. No purifier change found in iOS 26 or 27.
- Apple maps Matter onto existing HomeKit characteristics and ignores what it cannot map. [Forum thread 837127](https://developer.apple.com/forums/thread/837127).
- Wind modes are not rendered, so SleepWind is out. Mode Select has no tile.
- The overall air quality level displays. [Forum thread 843491](https://developer.apple.com/forums/thread/843491).
- A measurement cluster sharing another device's endpoint was dropped in one report. [Forum thread 801905](https://developer.apple.com/forums/thread/801905).
- Test vendor ID 0xFFF1 commissions with an "Uncertified Accessory" prompt and "Add Anyway". [Apple Matter OTA User Guide](https://developer.apple.com/accessories/Apple-Matter-OTA-User-Guide.pdf).
- Apple Home on-network commissioning of a device already on Wi-Fi works in user reports. No evidence that it supports Matter 1.4.2 Wi-Fi-only commissioning, so BLE is the retail path.
- Apple creates two fabrics per device. Removing the accessory from Home may not trigger a last-fabric reset, so a physical reset is needed.

## Target design

### Endpoint layout

| Endpoint | Device type | Clusters and features | Source in ESPHome | Apple Home |
|---|---|---|---|---|
| 0 | Root Node | Network Commissioning with our Wi-Fi driver | | |
| 1 | Air Purifier | Fan Control with MultiSpeed, SpeedMax 3, Auto. HEPA Filter Monitoring with Condition and ChangeIndication | levoit `fan`, `filter_life_left`, `filter_low`, `reset_filter_stats` | Tile toggle, percentage slider, auto control and filter status to be tested |
| 2 | Air Quality Sensor | Air Quality, PM2.5 Concentration Measurement | levoit `pm25`, `aqi` | Air quality level confirmed. Numeric PM2.5 to be tested |
| 3 | On/Off Plug-in Unit | On/Off | levoit fan preset Sleep | Outlet-style tile named Sleep |
| 4 | On/Off Plug-in Unit, optional | On/Off | levoit `display` switch | Outlet-style tile |
| 5 | On/Off Plug-in Unit, optional | On/Off | levoit `child_lock` switch | Outlet-style tile |

Timer, auto-mode profile and room size stay unexposed.

### Fan mapping rules

- Levoit speeds 1, 2, 3 map to PercentSetting 33, 67, 100 and SpeedSetting 1, 2, 3. Incoming percentages snap to 1 to 33, 34 to 66, 67 to 100, and the device reports the snapped value.
- FanMode Off maps to power off. Low, Medium, High map to speeds 1, 2, 3 with preset Manual.
- FanMode Auto maps to preset Auto. PercentSetting reports null and PercentCurrent reports the actual level if the MCU gives one.
- Sleep is the endpoint 3 switch. On sets preset Sleep. Off returns to Manual at the last speed. Setting a speed or Auto turns the switch off.
- `speed_count` and the preset list come from the ESPHome fan's traits, so Core 400S and 600S with four speeds work unchanged.

### Commissioning and reset behaviour

- **Unprovisioned boot.** Wi-Fi LED blinks. BLE advertises. The Matter commissioning window is open for 15 minutes.
- **Commissioning.** Phone connects over BLE, sends credentials, the driver hands them to ESPHome, ESPHome connects, the driver reports success, the phone finishes over IP. BLE shuts down.
- **Commissioned.** Wi-Fi LED solid, or off if that is less annoying at night.
- **Factory reset.** Clears fabrics, ACLs, ESPHome's saved Wi-Fi network, then reboots into the unprovisioned state. The setup code survives so the printed QR stays valid.
- **Reset trigger.** Currently six taps of Display Off in six seconds. Replace with the On/Off 15 second hold if the MCU reports it.

### Wi-Fi driver

`ESPHomeWiFiDriver : chip::DeviceLayer::NetworkCommissioning::WiFiDriver`

| Method | Behaviour |
|---|---|
| `Init` | Load the current ESPHome network into the staging slot. |
| `AddOrUpdateNetwork` | Store SSID and password in staging only. |
| `ConnectNetwork` | Hop to the main loop with `defer`. Call `set_sta` and `start_connecting`. Start a 30 s timer. |
| connect listener | On connect, hop to the Matter thread with `PlatformMgr().ScheduleWork` and call `OnResult(kSuccess)`. On timeout map the failure to `kAuthFailure`, `kNetworkNotFound` or `kOtherConnectionFailure`. |
| `CommitConfiguration` | Call `save_wifi_sta`. |
| `RevertConfiguration` | Restore the previous network or `clear_sta`. |
| `RemoveNetwork` | Clear staging. |
| `ScanNetworks` | Trigger ESPHome's scan and answer from `WiFiScanResultsListener`. |
| `GetNetworks` | One entry from staging, marked connected from `wifi::global_wifi_component->is_connected()`. |

Config changes in `__init__.py`:

- New option, for example `matter: ble_commissioning: true`, valid alongside `wifi:`.
- When set, enable `CONFIG_ENABLE_CHIPOBLE`, `CONFIG_BT_ENABLED`, `CONFIG_BT_NIMBLE_ENABLED`, `CONFIG_USE_BLE_ONLY_FOR_COMMISSIONING`, and the NimBLE reductions `CONFIG_BT_NIMBLE_MAX_CONNECTIONS=1`, `CONFIG_BT_NIMBLE_ROLE_CENTRAL=n`, `CONFIG_BT_NIMBLE_ROLE_OBSERVER=n`.
- Fail validation if `esp32_ble` is loaded.
- Set both rendezvous flags in the QR payload.
- `wifi:` needs to validate with no networks. Short term, declare an `ap:` with a very long `ap_timeout`. Long term, propose an ESPHome change so external components can register as a provisioner.

### Device YAML

See `levoit-core300s.yaml`. The endpoint section is:

```yaml
matter:
  ble_commissioning: true
  endpoints:
    1:
      air_purifier:
        fan_id: purifier_fan
        with_features: [multi_speed, auto]
        hepa_filter_condition: filter_life
        hepa_filter_change_indication: filter_low
      clusters:
        on_off:
    2:
      air_quality_sensor:
        pm_2_5: pm25
        air_quality: aqi
    3:
      id: sleep_endpoint
      on_off_plug_in_unit:
      on_attribute:
        on_off.on_off:
          - switch.control: ...
```

## Phases

### Phase 0. Parts and bench setup

- USB-UART adapter at 3.3 V, soldering kit, pry tool.
- One classic ESP32 dev board. Building for it with `CONFIG_FREERTOS_UNICORE: y` stands in for the SOLO on the desk.
- One XIAO ESP32-C6 as the fallback module.
- Fork esphome-matter. Create a working branch with a device-neutral name. Nothing added to the fork is Levoit-specific.

Done when both boards flash a plain ESPHome config.

### Phase 1. Open, back up, plain ESPHome

1. Follow the [Core 300S teardown](https://github.com/tuct/levoit/tree/main/devices/levoit-core300s). Solder TXD0, RXD0, IO0, 3V3, GND.
2. `esptool flash_id` to confirm flash size.
3. `esptool read_flash 0 ALL levoit-core300s-backup.bin`. Keep two copies.
4. Read the stock partition table from the dump.
5. Flash tuct's `levoit-core300s.yaml` unchanged.
6. Confirm fan, presets, PM2.5, filter, display, child lock, and one ESPHome OTA.
7. Sniff the UART while pressing every panel button and combination. Look for any frame that could serve as a reset trigger.

Done when the purifier runs ESPHome, updates over the air, and the backup restores on the bench.

### Phase 2. Fit spike, go/no-go

1. Write `partitions-4mb-matter.csv` with two 0x1E0000 app slots and a reduced NVS. Keep NVS at 96 KB or more because Matter fabrics and ESPHome preferences share it.
2. Add esphome-matter with on-network commissioning, which works today, and a bare `air_purifier` endpoint. Remove `api`, `captive_portal`, `web_server`, `debug`.
3. Apply flash reductions: `CONFIG_ENABLE_CHIP_SHELL=n`, `CONFIG_NEWLIB_NANO_FORMAT=y`, logger at `INFO`.
4. Record image size, free heap at boot, free heap after commissioning.
5. Hand-enable CHIPoBLE and NimBLE in `sdkconfig_options` and record size and heap again, even if commissioning does not work yet.

Go for the stock ESP32 if the BLE-enabled image is under about 1.85 MB and free heap with BLE up stays above about 25 KB. Otherwise switch to the C6, wired to the UART pads with the stock module's EN tied to GND. The rest of the plan is the same either way.

### Phase 3. Apple Home bench test

Build the full endpoint layout using `on_attribute` and `set_attribute` glue in YAML, with on-network commissioning. Then check in Home on iOS 27:

1. Does FanMode Auto show and round-trip?
2. Does HEPA Condition or ChangeIndication appear anywhere?
3. Are endpoints 1 and 2 grouped into one accessory? Is numeric PM2.5 shown?
4. How do the on/off plug endpoints group and name? Can they show as a switch?
5. Do scenes and automations see fan speed, air quality and the Sleep switch?

Adjust the endpoint table from the results. Decide whether display and child lock earn their tiles.

### Phase 4. Purifier mapping in esphome-matter

1. Fix `fan_control` feature codegen. Build on PR #94 and issue #91.
2. `MatterFan` mapping class beside `matter_lights.cpp`. Subscribe to the ESPHome fan's state callback and write Fan Control attributes. Handle attribute writes from Matter and issue `fan::FanCall`s. Guard against echo loops the way the light mapping does.
3. Filter mapping. Sensor to Condition, binary sensor to ChangeIndication, ResetCondition command to a button press.
4. Air quality enum mapping from a sensor with thresholds, or from PM2.5 directly.
5. `switch_id` on `on_off_plug_in_unit` if it is missing.
6. Template switch in the levoit package that represents Sleep.
7. Unit tests in `tests/unit` and a config in `tests/configs`.

Done when the phase 3 layout works with no YAML glue.

### Phase 5. BLE commissioning

1. `ble_commissioning` option and sdkconfig wiring.
2. `ESPHomeWiFiDriver` and the option A wrap.
3. Both rendezvous flags in the QR payload.
4. Wi-Fi with no stored network. Confirm ESPHome stays idle and does not start an AP during commissioning.
5. Commission from iPhone over BLE on the dev board, then on the purifier.
6. Failure cases: wrong password, SSID out of range, phone leaves mid-commissioning, power loss mid-commissioning, fail-safe expiry. In each the device must return to a commissionable state with no stored network.
7. Confirm BLE shuts down afterwards and heap recovers.
8. Reboot test. The device must rejoin Wi-Fi from ESPHome's stored network and Apple Home must reconnect.

Done when a factory-fresh flash commissions into Apple Home with only the QR code.

### Phase 6. Reset, LED, polish

1. `matter.factory_reset` gains `clear_wifi: true`, which also clears ESPHome's saved network.
2. Reset trigger from phase 1's sniffing. If the MCU reports nothing usable, use a pattern on an existing control, for example toggling child lock five times in ten seconds. Final fallback is a power-cycle counter stored in NVS.
3. Wi-Fi LED states through the levoit component's LED command: blink while commissionable, solid or off when connected.
4. Reopen the commissioning window when the last fabric is removed.
5. Print the QR code. Set `passcode` and `discriminator` in YAML so the label survives a full erase.
6. Stable `product_name`, `vendor_name`, hardware and software version strings.

### Phase 7. OTA workflow

1. Keep `ota: platform: esphome` with a password.
2. Document the update command: `esphome upload levoit-core300s.yaml --device <ip>`.
3. Confirm an OTA across a partition-table-compatible build keeps fabrics and Wi-Fi.
4. Add `safe_mode` if it fits, so a bad build can still take an OTA.
5. Leave the Matter OTA requestor off. Revisit only if a second controller is added.

### Phase 8. Upstream

| Piece | Destination |
|---|---|
| Thread gating | esphome-matter PR #115, already open |
| `fan_control` codegen fixes | esphome-matter, coordinate with PR #94 |
| Fan, filter, air quality mappings | esphome-matter |
| BLE commissioning with ESPHome-owned Wi-Fi | esphome-matter, continue issue #97 |
| Driver setter and early `ApplicationControlled` | `davidvtwout/esp_matter` fork, then espressif/esp-matter |
| External provisioner registration for `wifi` | esphome/esphome |
| Matter package and Core 300S Matter YAML | tuct/levoit `devices/packages` |
| Classic ESP32 partition table and size notes | esphome-matter docs |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Image does not fit 1.92 MB on the stock ESP32 | Medium | Phase 2 gate. C6 fallback. |
| Heap exhaustion during BLE commissioning on 520 KB RAM | Medium | NimBLE reductions, no `api`, measure in phase 2. |
| Matter + NimBLE + Wi-Fi unstable on single core | Unknown | Dev board test before opening the purifier. |
| Apple Home ignores Auto or filter status | Medium | Phase 3 before building mappings. Fall back to a switch endpoint for Auto. |
| ESPHome Wi-Fi internals change between releases | Medium | Use only the public calls `improv_ble` uses. Pin the ESPHome version. |
| Bad OTA on a closed unit | Low | `safe_mode`, serial pads stay accessible after one teardown. |
| esphome-matter config schema changes | High, stated in its README | Pin to a commit on the fork. Rebase deliberately. |

## Open questions

1. Core 300S flash size and stock partition table. Answered in phase 1.
2. What frame does the MCU send when On/Off is held for 5 and 15 seconds? Answered in phase 1.
3. Does Apple Home group the purifier and air quality endpoints? Answered in phase 3.
4. Should display and child lock be exposed at all, given the extra tiles and Siri's "turn everything off"? Decide after phase 3.
5. Does `resource_monitor` in esp-matter need a delegate for Condition updates? Check at the start of phase 4.

## Sources

- esphome-matter: [repo](https://github.com/DavidvtWout/esphome-matter), issues [#97 BLE](https://github.com/DavidvtWout/esphome-matter/issues/97), [#69 OTA](https://github.com/DavidvtWout/esphome-matter/issues/69), [#91](https://github.com/DavidvtWout/esphome-matter/issues/91), PRs [#94](https://github.com/DavidvtWout/esphome-matter/pull/94), [#115](https://github.com/DavidvtWout/esphome-matter/pull/115)
- levoit: [Core 300S guide](https://github.com/tuct/levoit/tree/main/devices/levoit-core300s), [UART protocol](https://github.com/tuct/levoit/blob/main/LEVOIT_UART.md)
- connectedhomeip ESP32 platform: `src/platform/ESP32/NetworkCommissioningDriver.cpp`, `ConnectivityManagerImpl_WiFi.cpp`, `ESP32Utils.cpp`
- esp-matter: `components/esp_matter/esp_matter_core.cpp`, [RAM and flash optimisations](https://docs.espressif.com/projects/esp-matter/en/latest/esp32/optimizations.html), [production guide](https://docs.espressif.com/projects/esp-matter/en/latest/esp32/production.html)
- ESPHome: `esphome/components/wifi`, `improv_ble`, `provisioning`, `esp32/__init__.py` for partitions
- Apple: [Matter OTA User Guide](https://developer.apple.com/accessories/Apple-Matter-OTA-User-Guide.pdf), [best practices](https://developer.apple.com/apple-home/downloads/Matter-Accessory-Best-Practices-for-Apple-Home.pdf), forum threads [837127](https://developer.apple.com/forums/thread/837127), [843491](https://developer.apple.com/forums/thread/843491), [844646](https://developer.apple.com/forums/thread/844646), [801905](https://developer.apple.com/forums/thread/801905)
- connectedhomeip: [Apple supported device types](https://github.com/project-chip/connectedhomeip/blob/master/docs/guides/darwin.md), [ESP32 OTA](https://github.com/project-chip/connectedhomeip/blob/master/docs/platforms/esp32/ota.md), [air purifier example](https://github.com/project-chip/connectedhomeip/blob/master/examples/air-purifier-app/air-purifier-common/air-purifier-app.matter)
