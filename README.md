# esphome-levoit-matter

> [!TIP]
> Don't need ESPHome? Use [levoit-matter](https://github.com/tadhglewis/levoit-matter).

Levoit air purifiers on Matter, using ESPHome. No cloud, no VeSync, no Home Assistant required. Pairs with Apple Home by QR code over Bluetooth.

**Status: runs on one Core 300S, paired to Apple Home. Best effort, no support.**

## What is going on here

ESPHome has no Matter support of its own. [DavidvtWout/esphome-matter](https://github.com/DavidvtWout/esphome-matter) adds it, but it is early and is missing what an air purifier needs:

| Missing upstream | Why a purifier needs it |
|---|---|
| Bluetooth pairing on Wi-Fi devices | Without it there is no "scan the QR code and it joins your Wi-Fi". |
| A way to map an ESPHome fan to a Matter fan | Speeds and Auto mode. |
| Filter life and air quality sensors | The filter status and the air quality tile. |
| Setting values on fan, filter and air quality from YAML | Keeping Matter in step with the purifier's own buttons. |

So this project is two things:

1. **A fork of esphome-matter that adds those features**: the `ble-commissioning-fan-mapping` branch of [tadhglewis/esphome-matter](https://github.com/tadhglewis/esphome-matter). Nothing in it is Levoit-specific, and the aim is to get all of it merged upstream. [`docs/UPSTREAM.md`](docs/UPSTREAM.md) lists each change and the plan.
2. **This repo: an example config that uses the fork** for a Levoit Core 300S. It is one YAML file and a partition table. The purifier itself is driven by [tuct/levoit](https://github.com/tuct/levoit), through the `feat/core-wifi-button-hold` branch of [tadhglewis/levoit](https://github.com/tadhglewis/levoit) until [#140](https://github.com/tuct/levoit/pull/140), [#141](https://github.com/tuct/levoit/pull/141), [#142](https://github.com/tuct/levoit/pull/142) and [#143](https://github.com/tuct/levoit/pull/143) are merged. Without them a Core 300S whose controller reports 1.0.0 shows no state at all.

Until the fork's changes are merged, you build against the fork. After that, this config should work with upstream esphome-matter and the fork goes away.

## Features

| Feature | In Apple Home |
|---|---|
| Power, 3 speeds | Purifier tile, percentage slider |
| Auto mode | Purifier mode, showing the speed the fan runs at |
| Filter life, change-filter flag | Filter status. Six months at full speed, counted by airflow. Hold Sleep for 3 seconds to reset. |
| PM2.5, air quality level | Air quality sensor |
| Sleep, Display, Child Lock | Three separate switches. Display reads off in Sleep and refuses to turn on. |
| Pairing | Scan the QR code. The phone sends Wi-Fi over Bluetooth. |
| Updates over Wi-Fi | ESPHome OTA from your machine |
| Factory reset | Hold the Wi-Fi button for 15 seconds. Keeps the setup code. |

## Known problems

- Sleep shows as the last manual speed.
- The Wi-Fi LED does nothing, and nothing shows that a reset hold has registered.
- Commands are not retried.
- A bad update is not rolled back on a health check.
- The setup code is random, made on first boot, and only printed in the log. Copy it from there.
- Test vendor ID. Apple shows an "uncertified accessory" prompt once.
- The 15-second reset is wired up but has not been held to the end on hardware.

## Quick start

You need the case open and a 3.3 V USB serial adapter.

```bash
python3 -m venv .venv && .venv/bin/pip install esphome==2026.11.0
git clone -b ble-commissioning-fan-mapping https://github.com/tadhglewis/esphome-matter.git esphome-matter
cp secrets.yaml.example secrets.yaml   # set a real OTA password
.venv/bin/esphome run levoit-core300s.yaml --device /dev/cu.usbserial-XXXX
```

The log prints a QR code link. Scan it in Apple Home.

That is the short version. **Read [`FLASHING.md`](FLASHING.md) before you open the purifier.** It covers wiring, backing up the stock firmware, pairing, updates and resets.

## Licence

MIT. See [`LICENSE`](LICENSE).
