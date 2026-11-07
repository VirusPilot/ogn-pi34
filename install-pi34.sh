#!/bin/bash

set -e

if (( $# == 0 )); then
  printf 'Usage: %s [ogn|dump1090|ogn2readsb]\n' "$0"
  exit 0
fi

MODE=$1
if (( $# > 1 )); then
  printf 'Usage: %s [ogn|dump1090|ogn2readsb]\n' "$0" >&2
  exit 2
fi
case "$MODE" in
  ogn|dump1090|ogn2readsb)
    ;;
  *)
    printf 'Usage: %s [ogn|dump1090|ogn2readsb]\n' "$0" >&2
    exit 2
    ;;
esac

cd /home/pi || { echo "Error: /home/pi doesn't exist!" >&2; exit 1; }

PACKAGES=(
  librtlsdr-dev librtlsdr0 rtl-sdr git cmake libfftw3-bin libusb-1.0-0-dev
  lynx chrony procserv telnet netcat-traditional debhelper unzip
)
case "$MODE" in
  dump1090)
    PACKAGES+=(build-essential fakeroot pkg-config libncurses5-dev)
    ;;
  ogn2readsb)
    PACKAGES+=(lighttpd build-essential fakeroot pkg-config libncurses5-dev
      python3-pip python3-aiohttp gettext-base)
    ;;
esac

sudo apt update
sudo apt install "${PACKAGES[@]}" -y
sudo apt autoremove -y

# Legacy DVB-T TV drivers may enable the bias tee which may damage the RTL-SDR dongle. Blacklist the drivers to avoid this.
echo 'blacklist dvb_usb_rtl28xxu' | sudo tee --append /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

BIT=$(getconf LONG_BIT)
DIST=$(lsb_release -r -s)
case "${BIT}_${DIST}" in
  64_13)
    platform="64-bit Debian 13 Trixie"
    tarball=ogn-pi34/rtlsdr-ogn-bin-arm64-0.3.3.tgz
    ;;
  32_13)
    platform="32-bit Debian 13 Trixie"
    tarball=ogn-pi34/rtlsdr-ogn-bin-ARM-0.3.3.tgz
    ;;
  *)
    printf 'Error: this script does not support platform %s-bit Debian %s.\n' "$BIT" "$DIST" >&2
    exit 1
    ;;
esac
printf '\nOGN receiver installation\n  Platform: %s\n  Installation: %s\n\n' "$platform" "$MODE"
printf 'Press Enter to continue, or Ctrl+C to cancel.\n'
read -r
tar xvf "$tarball"

cp -v ogn-pi34/Template.conf rtlsdr-ogn/Template.conf
printf '\nReceiver configuration\n'
printf 'Edit rtlsdr-ogn/Template.conf and set:\n'
printf '  - PPM correction and GSM calibration frequency\n'
printf '  - Receiver location and APRS name\n'
if [[ "$MODE" == ogn2readsb ]]; then
  printf '  - Server = "localhost:14580" to enable the APRS server function\n'
fi
printf '\nPress Enter to open the configuration file.\n'
read -r
nano rtlsdr-ogn/Template.conf

cp -v ogn-pi34/WW15MGH.DAC rtlsdr-ogn/WW15MGH.DAC
sudo cp -v rtlsdr-ogn/rtlsdr-ogn.conf /etc/rtlsdr-ogn.conf
sudo cp -v ogn-pi34/rtlsdr-ogn.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable rtlsdr-ogn
sudo systemctl start rtlsdr-ogn

case "$MODE" in
  dump1090)
    cd
    git clone https://github.com/VirusPilot/dump1090.git
    cd dump1090
    sudo dpkg-buildpackage -b --no-sign --build-profiles=custom,rtlsdr
    cd ..
    sudo dpkg -i dump1090-fa_*.deb
    rm -f dump1090-fa_*.deb dump1090-fa_*.buildinfo dump1090-fa_*.changes

    printf '\ndump1090-fa configuration\n'
    printf 'Set the receiver serial number and location in /etc/default/dump1090-fa.\n'
    printf 'Example: RECEIVER_SERIAL=1090, RECEIVER_LAT=50.000, RECEIVER_LON=10.000\n\n'
    printf 'Press Enter to open the configuration file.\n'
    read -r
    sudo nano /etc/default/dump1090-fa
    sudo systemctl restart dump1090-fa
    ;;
  ogn2readsb)
    cd
    sudo bash -c "$(wget -O - https://github.com/wiedehopf/adsb-scripts/raw/master/readsb-install.sh)"

    printf '\nreadsb configuration\n'
    printf 'Edit /etc/default/readsb and set the device ID (or serial) and receiver coordinates.\n'
    printf 'Add --net-sbs-jaero-in-port 30008 --jaero-timeout 1 to NET_OPTIONS.\n\n'
    printf 'Example settings:\n'
    printf '%s\n' \
      '  RECEIVER_OPTIONS="--device 1090 --device-type rtlsdr --gain auto-verbose --ppm 0"' \
      '  DECODER_OPTIONS="--lat 48.0 --lon 10.0 --max-range 0 --write-json-every 1"' \
      '  NET_OPTIONS="--net --net-ri-port 30001 --net-ro-port 30002 \' \
      '    --net-sbs-port 30003 --net-bi-port 30004,30104 \' \
      '    --net-bo-port 30005 --net-sbs-jaero-in-port 30008 --jaero-timeout 1"' \
      '  JSON_OPTIONS="--json-location-accuracy 2 --range-outline-hours 24"'
    printf '\nPress Enter to open the configuration file.\n'
    read -r
    sudo nano /etc/default/readsb

    printf '%s\n' 'jaeroTimeout = 60;' 'jaeroLabel = "OGN";' |
      sudo tee -a /usr/local/share/tar1090/html/config.js >/dev/null
    sudo cp -f ogn-pi34/Platzrunden+Segler_N_5.25.7.geojson \
      /usr/local/share/tar1090/html/geojson/UK_Mil_RC.geojson

    cd
    git clone https://github.com/glidernet/python-ogn-client
    cd python-ogn-client
    pip3 install --break-system-packages .

    cd
    git clone https://github.com/b3nn0/ogn2dump1090
    cd ogn2dump1090
    wget -O ddb.json 'http://ddb.glidernet.org/download/?j=1'
    printf '\nogn2dump1090 configuration\n'
    printf 'Edit config.py with your APRS credentials and subscription filter.\n'
    printf 'Example filter:\n  aprs_subscribe_filter = "r/48.0/10.0/20"\n\n'
    printf 'Press Enter to open the configuration file.\n'
    read -r
    sudo nano config.py
    OGN2DUMP1090DIR=$(pwd) envsubst < ogn2dump1090.service.template > ogn2dump1090.service
    sudo mv ogn2dump1090.service /etc/systemd/system/
    sudo systemctl enable ogn2dump1090
    sudo systemctl start ogn2dump1090
    ;;
esac

echo
read -r -t 1 -n 10000 discard || true
read -r -p "Installation complete. Reboot now? [y/N]: " -n 1
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Rebooting..."
  sleep 2
  sudo reboot
else
  echo "Reboot skipped. Run 'sudo reboot' manually when ready."
fi
