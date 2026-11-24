# Build and flash

For the Levoit Core 300S on its stock ESP32-SOLO-1C.

**This has not run on hardware.** These steps are written from the build tooling, not from a successful flash. Expect to adjust them.

Commands assume macOS and the repo root as the working directory.

## 1. Build

```bash
python3 -m venv .venv && .venv/bin/pip install esphome==2026.11.0
git clone -b ble-commissioning-fan-mapping https://github.com/tadhglewis/esphome-matter.git esphome-matter
cp secrets.yaml.example secrets.yaml
```

Edit `secrets.yaml` and set a real `ota_password`. Then:

```bash
.venv/bin/esphome compile levoit-core300s.yaml
```

The first compile downloads ESP-IDF and the Matter SDK and takes 15 to 30 minutes. Later ones take a couple of minutes. Output is in `.esphome/build/levoit-core300s/`. Expect about 1.46 MB.

## 2. Wire the purifier

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

## 3. Back up the stock firmware

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

## 4. Flash

With the chip in its bootloader:

```bash
.venv/bin/esphome run levoit-core300s.yaml --device $PORT
```

This writes the bootloader, the partition table and the app, then opens the serial log. The partition table in `partitions-4mb-matter.csv` differs from ESPHome's default, so the first flash must be serial.

## 5. Pair

The log prints the setup code after boot:

```
[C][matter]:   SetupQRCode: MT:...
[C][matter]:   QR URL: https://project-chip.github.io/connectedhomeip/qrcode.html?data=MT:...
[C][matter]:   Manual pairing code: ....-...-....
```

Open the URL to get a QR image. In Apple Home choose Add Accessory, scan it, and accept the uncertified accessory prompt. The phone sends Wi-Fi credentials over Bluetooth.

If Bluetooth pairing fails, set Wi-Fi over the serial cable with Improv from [web.esphome.io](https://web.esphome.io) in Chrome, then add the accessory.

## 6. Update over Wi-Fi

```bash
.venv/bin/esphome run levoit-core300s.yaml --device levoit-core300s.local
```

Use the IP address if `.local` does not resolve.

## 7. Factory reset

Hold the Wi-Fi button for 15 seconds. This clears Matter pairing and the saved Wi-Fi network, then reboots into pairing mode. The setup code stays the same. If that fails, erase over serial and flash again:

```bash
.venv/bin/esptool --port $PORT erase-flash
```

## 8. What to watch on the first boot

- A `heap` log line prints every 60 seconds. Free heap during Bluetooth pairing is the main unknown on this chip.
- `Reverting to no WiFi network` means Bluetooth pairing failed after Wi-Fi was sent. Try again.
