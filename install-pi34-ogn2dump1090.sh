#!/bin/bash
#set -x

sudo apt update
sudo apt install git cmake lighttpd build-essential fakeroot pkg-config libncurses5-dev libfftw3-bin libusb-1.0-0-dev lynx ntp ntpdate procserv telnet netcat-traditional debhelper python3-pip python3-aiohttp -y

ARCH=$(getconf LONG_BIT)
DIST=$(lsb_release -r -s)

# compile and install librtlsdr from https://github.com/osmocom/rtl-sdr
cd
git clone https://github.com/osmocom/rtl-sdr
cd rtl-sdr
sudo dpkg-buildpackage -b --no-sign
cd
sudo dpkg -i *.deb
rm -f *.deb
rm -f *.buildinfo
rm -f *.changes

# legacy DVB-T TV drivers need to be properly blacklisted (e.g. they will activate the bias tee by default)
echo 'blacklist dvb_usb_rtl28xxu' | sudo tee --append /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

# install rtlsdr-ogn
if [ "$ARCH" -eq 64 ] && [ "$DIST" -ge 12 ]; then
  wget http://download.glidernet.org/arm64/rtlsdr-ogn-bin-arm64-0.3.2.tgz
else
  if [ "$ARCH" -eq 32 ] && [ "$DIST" -ge 11 ]; then
    wget wget http://download.glidernet.org/arm/rtlsdr-ogn-bin-ARM-0.3.2.tgz
  else
    echo
    echo "wrong platform for this script, exiting"
    echo
    exit
  fi
fi
tar xvf *.tgz
cp -f ogn-pi34/Template.conf rtlsdr-ogn/Template.conf
cd rtlsdr-ogn
sudo chown root gsm_scan ogn-rf rtlsdr-ogn
sudo chmod a+s gsm_scan ogn-rf rtlsdr-ogn
echo
echo "Please edit Template.conf, to set-up the receiver:"
echo "- enter your ppm correction, GSM frequency for calibration, geographical position and APRS name"
echo "- add Server = "localhost:14580"; if you want to use the APRS server function"
echo
read -p "Press any key to continue"
sudo nano Template.conf
# download altitude correction file (difference between the Earth's ellipsoidal shape and the actual mean sea level)
wget http://download.glidernet.org/common/WW15MGH.DAC
# install rtlsdr-ogn service
sudo cp -v rtlsdr-ogn /etc/init.d/rtlsdr-ogn
sudo cp -v rtlsdr-ogn.conf /etc/rtlsdr-ogn.conf
sudo update-rc.d rtlsdr-ogn defaults

# install readsb
cd
sudo bash -c "$(wget -O - https://github.com/wiedehopf/adsb-scripts/raw/master/readsb-install.sh)"

echo
echo "Now the readsb config file needs to be modified as follows,"
echo "modify the device ID (or serial) and your receiver coordinates"
echo "and don't forget to add --net-sbs-in-port 30008 to NET_OPTIONS"
echo
echo "RECEIVER_OPTIONS="--device 1090 --device-type rtlsdr --gain auto-verbose --ppm 0""
echo "DECODER_OPTIONS="--lat 48.0 --lon 10.0 --max-range 450 --write-json-every 1""
echo NET_OPTIONS="--net --net-ri-port 30001 --net-ro-port 30002 --net-sbs-port 30003 --net-bi-port 30004,30104 --net-bo-port 30005 --net-sbs-jaero-in-port 30008 --jaero-timeout 1"
echo
read -p "Press any key to continue"
sudo nano /etc/default/readsb

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
echo "metar_source = "ETHN""
echo
read -p "Press any key to continue"
sudo nano config.py
OGN2DUMP1090DIR=$(pwd) envsubst < ogn2dump1090.service.template > ogn2dump1090.service
sudo mv ogn2dump1090.service /etc/systemd/system/
sudo systemctl enable ogn2dump1090
sudo systemctl start ogn2dump1090

echo
read -t 1 -n 10000 discard
read -p "Reboot now? [y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo reboot
fi
