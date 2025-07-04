#!/bin/bash
#set -x

sudo apt update
sudo apt install git cmake lighttpd build-essential fakeroot pkg-config libncurses5-dev libfftw3-bin libusb-1.0-0-dev lynx systemd-timesyncd procserv telnet netcat-traditional debhelper -y
sudo apt autoremove -y

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
echo "enter your ppm correction, GSM frequency for calibration, geographical position and APRS name"
echo
read -p "Press any key to continue"
sudo nano Template.conf

wget http://download.glidernet.org/common/WW15MGH.DAC

# install rtlsdr-ogn service
sudo cp -v rtlsdr-ogn /etc/init.d/rtlsdr-ogn
sudo cp -v rtlsdr-ogn.conf /etc/rtlsdr-ogn.conf
sudo update-rc.d rtlsdr-ogn defaults

# install systemd-timesyncd and enable ntp sync
sudo systemctl enable systemd-timesyncd
sudo systemctl start systemd-timesyncd
sudo timedatectl set-ntp true

# install dump1090-fa service
cd
git clone https://github.com/VirusPilot/dump1090.git
cd dump1090
sudo dpkg-buildpackage -b --no-sign --build-profiles=custom,rtlsdr
cd ..
sudo dpkg -i *.deb
rm -f *.deb
rm -f *.buildinfo
rm -f *.changes

echo
echo "Now the dump1090-fa config file needs to be edited, e.g. RECEIVER_SERIAL=1090, RECEIVER_LAT=50.000 and RECEIVER_LON=10.000"
echo
read -p "Press any key to continue"
sudo nano /etc/default/dump1090-fa

echo
read -t 1 -n 10000 discard
read -p "Reboot now? [y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo reboot
fi
