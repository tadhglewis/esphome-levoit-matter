# Switching with levoit-matter

This branch only. For one purifier that runs [levoit-matter](https://github.com/tadhglewis/levoit-matter) and sometimes this config, updated over Wi-Fi both ways.

Both use the same partition table and the same `fctry` factory data, so one QR label pairs either. Each erases the other's settings on its first boot, so nothing carries over: not pairing, not Wi-Fi, not filter life. levoit-matter's side is the [`dual-firmware`](https://github.com/tadhglewis/levoit-matter/tree/dual-firmware) branch.

## To this config

levoit-matter has to be a build with `CONFIG_LEVOIT_HTTP_OTA=y`. Its normal update is Matter OTA Software Update, which only takes a Matter `.ota` image with a higher version from the same vendor and product, and this config builds none. Without it, switching needs serial.

1. Remove the purifier from Home.
2. Build, then send it with levoit-matter's HTTP update:

```bash
.venv/bin/esphome compile levoit-core300s.yaml
../levoit-matter/tools/ota.sh <ip> .esphome/build/levoit-core300s/build/firmware.ota.bin
```

3. It boots, erases levoit-matter's settings and reboots. Scan the label.

## Back to levoit-matter

1. Remove the purifier from Home.
2. Build levoit-matter's `dual-firmware` branch, then send it with ESPHome's OTA:

```bash
.venv/bin/esphome upload levoit-core300s.yaml --device <ip> --file ../levoit-matter/build/levoit_matter.bin
```

3. It boots, erases this config's settings and reboots. Scan the label, then set filter life with `tools/filter.sh`.

A rollback to the other firmware after a failed update is cleaned up the same way.
