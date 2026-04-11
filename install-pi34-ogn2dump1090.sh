#!/bin/bash
#set -x

cd /home/pi || { echo "Error: /home/pi doesn't exist!"; exit 1; }

sudo apt update
sudo apt install librtlsdr-dev librtlsdr0 rtl-sdr git cmake lighttpd build-essential fakeroot pkg-config libncurses5-dev libfftw3-bin libusb-1.0-0-dev lynx chrony procserv telnet netcat-traditional debhelper python3-pip python3-aiohttp -y
sudo apt autoremove -y

# legacy DVB-T TV drivers need to be properly blacklisted (e.g. they will activate the bias tee by default)
echo 'blacklist dvb_usb_rtl28xxu' | sudo tee --append /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

# install rtlsdr-ogn
ARCH=$(arch) # linux architecture 
DIST=$(lsb_release -r -s) # linux OS release number
case "${ARCH}_${DIST}" in
  aarch64_13)
    echo
    echo "installing OGN v0.3.3 on aarch64 Debian 13 Trixie"
    echo "press Return to continue or Ctr-C to abort"
    read -r
    tar xvf ogn-pi34/rtlsdr-ogn-bin-arm64-0.3.3.tgz
    ;;
  *)
    echo
    echo "wrong platform for this script, exiting"
    echo
    exit 1
    ;;
esac

# prepare OGN configuration file
cp -v ogn-pi34/Template.conf rtlsdr-ogn/Template.conf
echo
echo "Please edit Template.conf, to set-up the receiver:"
echo "- enter your ppm correction, GSM frequency for calibration, geographical position and APRS name"
echo "- add Server = "localhost:14580"; if you want to use the APRS server function"
echo
read -p "Press any key to continue"
nano rtlsdr-ogn/Template.conf

# download EGM grid file
wget http://download.glidernet.org/common/WW15MGH.DAC -O rtlsdr-ogn/WW15MGH.DAC

# enable and start rtlsdr-ogn service
sudo cp -v rtlsdr-ogn/rtlsdr-ogn.conf /etc/rtlsdr-ogn.conf
sudo cp -v ogn-pi34/rtlsdr-ogn.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable rtlsdr-ogn
sudo systemctl start rtlsdr-ogn

# install readsb
cd
sudo bash -c "$(wget -O - https://github.com/wiedehopf/adsb-scripts/raw/master/readsb-install.sh)"

echo
echo "Now the readsb config file needs to be modified as follows,"
echo "modify the device ID (or serial) and your receiver coordinates"
echo "and don't forget to add --net-sbs-jaero-in-port 30008 --jaero-timeout 1 to NET_OPTIONS"
echo
echo 'RECEIVER_OPTIONS="--device 1090 --device-type rtlsdr --gain auto-verbose --ppm 0"'
echo 'DECODER_OPTIONS="--lat 48.0 --lon 10.0 --max-range 0 --write-json-every 1"'
echo 'NET_OPTIONS="--net --net-ri-port 30001 --net-ro-port 30002 --net-sbs-port 30003 --net-bi-port 30004,30104 --net-bo-port 30005 --net-sbs-jaero-in-port 30008 --jaero-timeout 1"'
echo 'JSON_OPTIONS="--json-location-accuracy 2 --range-outline-hours 24"'
echo
read -p "Press any key to continue"
sudo nano /etc/default/readsb

# relabel OGN traffic
cd /usr/local/share/tar1090/html &&  \
  echo 'jaeroTimeout = 60;' | sudo tee -a /usr/local/share/tar1090/html/config.js &&  \
  echo 'jaeroLabel = "OGN";' | sudo tee -a /usr/local/share/tar1090/html/config.js

# add traffic patterns
cd
sudo cp -f ogn-pi34/Platzrunden+Segler_N_5.25.5.geojson /usr/local/share/tar1090/html/geojson/UK_Mil_RC.geojson

# install python-ogn-client (required for ogn2dump1090)
cd
git clone https://github.com/glidernet/python-ogn-client
cd python-ogn-client
pip3 install --break-system-packages .

# install ogn2dump1090
cd
git clone https://github.com/b3nn0/ogn2dump1090
cd ogn2dump1090
wget -O ddb.json http://ddb.glidernet.org/download/?j=1
echo
echo "Now the ogn2dump1090 config file needs to be edited according to your credentials, e.g:"
echo
echo "aprs_subscribe_filter = "r/48.0/10.0/20""
echo
read -p "Press any key to continue"
sudo nano config.py
OGN2DUMP1090DIR=$(pwd) envsubst < ogn2dump1090.service.template > ogn2dump1090.service
sudo mv ogn2dump1090.service /etc/systemd/system/
sudo systemctl enable ogn2dump1090
sudo systemctl start ogn2dump1090

echo
read -t 1 -n 10000 discard  # Clear input buffer
read -p "Installation complete. Reboot now? [y/n]: " -n 1 -r
echo    # New line after input
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    sleep 2
    sudo reboot
else
    echo "Reboot skipped. Run 'sudo reboot' manually when ready."
fi
