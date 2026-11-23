# esphome-levoit-matter

ESPHome config that puts a Levoit Core 300S on Matter. No cloud, no VeSync, no Home Assistant required. Pairs with Apple Home by QR code over Bluetooth.

**Status: compiles. Has never run on hardware. Best effort, no support.**

If you want a firmware rather than an ESPHome config, use [levoit-matter](https://github.com/tadhglewis/levoit-matter). It is the same purifier on Espressif's Matter SDK directly, and it is where the work goes.

## What this is

One YAML file and a partition table. The rest is other people's code:

- [tuct/levoit](https://github.com/tuct/levoit) drives the purifier.
- [DavidvtWout/esphome-matter](https://github.com/DavidvtWout/esphome-matter) provides Matter, through the branch `ble-commissioning-fan-mapping` of [tadhglewis/esphome-matter](https://github.com/tadhglewis/esphome-matter). The branch adds Bluetooth commissioning, a fan mapping, and filter and air quality sensors. Nothing in it is Levoit-specific. Once it is merged upstream, the local clone below goes away.

## Features

| Feature | In Apple Home |
|---|---|
| Power, 3 speeds | Purifier tile, percentage slider |
| Auto mode | Purifier mode. Unverified in Home. |
| Sleep, Display, Child Lock | Three separate switches |
| Filter life, change-filter flag | Filter status. Unverified in Home. |
| PM2.5, air quality level | Air quality sensor |
| Pairing | Scan QR, phone sends Wi-Fi over Bluetooth |
| Updates over Wi-Fi | ESPHome OTA from your machine |
| Factory reset | Tap Display Off six times within six seconds |

## Known problems

- Sleep shows as the last manual speed. Picking that same speed does not leave Sleep.
- The Wi-Fi LED does nothing.
- Commands are not retried, and state is not requested when the purifier goes quiet.
- A bad update is not rolled back on a health check.
- Test vendor ID. Apple shows an "uncertified accessory" prompt once.
- Free memory during Bluetooth pairing on the stock chip is unmeasured.

## Build

```bash
python3 -m venv .venv && .venv/bin/pip install esphome==2026.11.0
git clone -b ble-commissioning-fan-mapping https://github.com/tadhglewis/esphome-matter.git esphome-matter
cp secrets.yaml.example secrets.yaml   # set a real OTA password
.venv/bin/esphome compile levoit-core300s.yaml
```

The first compile takes 15 to 30 minutes. Output is in `.esphome/build/levoit-core300s/`. About 1.46 MB in a 1.94 MB slot.

## Wire the purifier

You need a 3.3 V USB serial adapter. Do not use 5 V.

Keep the purifier unplugged from the wall the whole time the case is open. The board is powered from the adapter.

1. Unplug the purifier.
2. Remove the base cover and filter, then the eight screws underneath. Separate the base from the sleeve and unplug the logic board. Photos are in the [tuct/levoit Core 300S guide](https://github.com/tuct/levoit/tree/main/devices/levoit-core300s).
3. Solder or clip wires to the pads next to the ESP32 module:

| Board pad | Adapter |
|---|---|
| `TXD0` | RX |
| `RXD0` | TX |
| `GND` | GND |
| `+3V3` | 3.3 V |
| `IO0` | GND, only while powering on |

4. Hold `IO0` to ground, connect the adapter to USB, then release `IO0`. The chip is now in its bootloader.
5. Find the port:

```bash
ls /dev/cu.usbserial-* /dev/cu.wchusbserial-* 2>/dev/null
```

The steps below call it `$PORT`:

```bash
export PORT=/dev/cu.usbserial-XXXX
```

Every flashing command needs the chip in its bootloader. If a command cannot connect, repeat step 4.

## Back up the stock firmware

Do this once, before anything else. It is the only way back to VeSync.

```bash
.venv/bin/esptool --port $PORT flash-id
.venv/bin/esptool --port $PORT read-flash 0 ALL stock-backup.bin
```

`flash-id` must report a 4 MB flash. If it does not, stop: the partition tables here assume 4 MB.

Keep two copies of `stock-backup.bin` somewhere that is not this laptop.

To restore the stock firmware later:

```bash
.venv/bin/esptool --port $PORT erase-flash
.venv/bin/esptool --port $PORT write-flash 0x0 stock-backup.bin
```

## Flash

With the chip in its bootloader:

```bash
.venv/bin/esphome run levoit-core300s.yaml --device $PORT
```

This writes the bootloader, the partition table and the app, then opens the serial log. The partition table in `partitions-4mb-matter.csv` differs from ESPHome's default, so the first flash must be serial.

## Pair

The log prints the setup code after boot:

```
[C][matter]:   SetupQRCode: MT:...
[C][matter]:   QR URL: https://project-chip.github.io/connectedhomeip/qrcode.html?data=MT:...
[C][matter]:   Manual pairing code: ....-...-....
```

Open the URL to get a QR image. In Apple Home choose Add Accessory, scan it, and accept the uncertified accessory prompt. The phone sends Wi-Fi credentials over Bluetooth.

If Bluetooth pairing fails, set Wi-Fi over the serial cable with Improv from [web.esphome.io](https://web.esphome.io) in Chrome, then add the accessory.

## Update over Wi-Fi

```bash
.venv/bin/esphome run levoit-core300s.yaml --device levoit-core300s.local
```

Use the IP address if `.local` does not resolve.

## Factory reset

Tap Display Off six times within six seconds. This clears Matter pairing and the saved Wi-Fi network, then reboots into pairing mode. If that fails, erase over serial and flash again:

```bash
.venv/bin/esptool --port $PORT erase-flash
```

## What to watch on first boot

- A `heap` log line prints every 60 seconds. Free heap during Bluetooth pairing is the main unknown on this chip.
- `Reverting to no WiFi network` means Bluetooth pairing failed after Wi-Fi was sent. Try again.

## Layout

| Path | What |
|---|---|
| `levoit-core300s.yaml` | Device config. All purifier-specific logic lives here. |
| `partitions-4mb-matter.csv` | Partition table. Two 1.94 MB app slots. |
| `docs/PLAN.md` | Design, review findings and the plan for sending the fork's changes upstream. |
