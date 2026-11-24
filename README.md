# esphome-levoit-matter

Levoit air purifiers on Matter, using ESPHome. No cloud, no VeSync, no Home Assistant required. Pairs with Apple Home by QR code over Bluetooth.

**Status: compiles. Has never run on hardware. Best effort, no support.**

**If you do not need ESPHome, use [levoit-matter](https://github.com/tadhglewis/levoit-matter).** It is the same purifier on Espressif's Matter SDK, esp-matter, directly. It runs on a real Core 300S, needs no fork, and covers more models. Use this repo only if you want the purifier inside an ESPHome setup.

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
2. **This repo: an example config that uses the fork** for a Levoit Core 300S. It is one YAML file and a partition table. The purifier itself is driven by [tuct/levoit](https://github.com/tuct/levoit).

Until the fork's changes are merged, you build against the fork. After that, this config should work with upstream esphome-matter and the fork goes away.

## Features

| Feature | In Apple Home |
|---|---|
| Power, 3 speeds | Purifier tile, percentage slider |
| Auto mode | Purifier mode. Unverified in Home. |
| Filter life, change-filter flag | Filter status. Unverified in Home. |
| PM2.5, air quality level | Air quality sensor |
| Sleep, Display, Child Lock | Three separate switches |
| Pairing | Scan the QR code. The phone sends Wi-Fi over Bluetooth. |
| Updates over Wi-Fi | ESPHome OTA from your machine |
| Factory reset | Tap Display Off six times within six seconds |

## Known problems

- Sleep shows as the last manual speed. Picking that same speed does not leave Sleep.
- The Wi-Fi LED does nothing.
- Commands are not retried, and state is not requested when the purifier goes quiet.
- A bad update is not rolled back on a health check.
- Test vendor ID. Apple shows an "uncertified accessory" prompt once.
- Free memory during Bluetooth pairing on the stock chip is unmeasured.

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
