# esphome-levoit-matter

ESPHome config that puts a Levoit Core 300S on Matter. No cloud, no VeSync, no Home Assistant required. Pairs with Apple Home by QR code over Bluetooth.

**Status: compiles. Has never run on hardware. Best effort, no support.**

If you want a firmware and not an ESPHome config, use [levoit-matter](https://github.com/tadhglewis/levoit-matter). It is the same purifier on Espressif's Matter SDK directly, it covers more models, and it is where the work goes.

## What this is

One YAML file and a partition table. The rest is other people's code:

- [tuct/levoit](https://github.com/tuct/levoit) drives the purifier.
- [DavidvtWout/esphome-matter](https://github.com/DavidvtWout/esphome-matter) provides Matter, through the `ble-commissioning-fan-mapping` branch of [tadhglewis/esphome-matter](https://github.com/tadhglewis/esphome-matter). See [`docs/UPSTREAM.md`](docs/UPSTREAM.md) for what the branch adds.

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

## Layout

| Path | What |
|---|---|
| `levoit-core300s.yaml` | Device config. All purifier-specific logic lives here. |
| `partitions-4mb-matter.csv` | Partition table. Two 1.94 MB app slots. |
| `FLASHING.md` | Build, flash, pair, update, reset. |
| `docs/UPSTREAM.md` | What the esphome-matter branch changes and the plan for sending it upstream. |
