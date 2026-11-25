#!/bin/sh
set -e
usage() {
  echo "usage: $0 [-d device] [--new]" >&2
  echo "Makes one purifier's setup code and QR label in devices/<device>/." >&2
  exit 1
}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEVICE=purifier
if [ "$1" = "-d" ]; then
  [ -n "$2" ] || usage
  DEVICE="$2"
  shift 2
fi
case "$1" in -h | --help) usage ;; esac
case "$DEVICE" in
  *[!A-Za-z0-9_-]* | "") echo "device name may only use letters, digits, - and _" >&2; exit 1 ;;
esac
DEVICE_DIR="$ROOT/devices/$DEVICE"
SECRETS="$DEVICE_DIR/secrets"
VENV="$ROOT/.venv-mfg"

show() {
  echo
  echo "Device folder:  $DEVICE_DIR"
  echo "QR code image:  $SECRETS/qrcode.png"
  awk -F, 'NR==2 { print "QR code text:   " $1; print "Manual code:    " $2 }' "$SECRETS/setup-codes.csv"
  echo
  echo "Write it once, with the chip in its bootloader:"
  echo "  .venv/bin/esptool --port <port> --after no-reset write-flash 0x1A000 $DEVICE_DIR/fctry.bin"
  echo "Back up $DEVICE_DIR. It is the only copy of this purifier's setup code."
}

if [ -e "$DEVICE_DIR/fctry.bin" ] && [ "$1" != "--new" ]; then
  echo "Factory data for '$DEVICE' already exists. Pass --new to replace it, which invalidates the old label."
  show
  exit 0
fi

if [ ! -x "$VENV/bin/esp-matter-mfg-tool" ]; then
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install -q --disable-pip-version-check esp-matter-mfg-tool==1.0.29
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
(cd "$WORK" && "$VENV/bin/esp-matter-mfg-tool" -v 0xFFF1 -p 0x8000 -s 0x6000 -dm 2 \
  --outdir out >"$WORK/log" 2>&1) || { cat "$WORK/log"; exit 1; }
TOOL_OUT=$(dirname "$(find "$WORK/out" -name '*-partition.bin')")

mkdir -p "$SECRETS"
chmod 700 "$ROOT/devices" "$DEVICE_DIR" "$SECRETS"
cp "$TOOL_OUT"/*-partition.bin "$DEVICE_DIR/fctry.bin"
cp "$TOOL_OUT"/*-qrcode.png "$SECRETS/qrcode.png"
cp "$TOOL_OUT"/*-onb_codes.csv "$SECRETS/setup-codes.csv"
chmod 600 "$DEVICE_DIR/fctry.bin" "$SECRETS"/*
show
