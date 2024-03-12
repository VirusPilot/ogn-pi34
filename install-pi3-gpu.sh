#!/bin/bash
#set -x

sudo apt update
sudo apt install libfftw3-bin libusb-1.0-0-dev lynx ntp ntpdate procserv telnet -y

ARCH=$(getconf LONG_BIT)
DIST=$(lsb_release -r -s)

# install librtlsdr
if [ $ARCH -eq 64 ]; then
    wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr0_0.6.0-4_arm64.deb
    wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr-dev_0.6.0-4_arm64.deb
    wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/rtl-sdr_0.6.0-4_arm64.deb
else
    wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr0_0.6.0-4_armhf.deb
    wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr-dev_0.6.0-4_armhf.deb
    wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/rtl-sdr_0.6.0-4_armhf.deb
fi
sudo dpkg -i *.deb
rm -f *.deb

# Bookworm: Debian 12 (32bit and 64bit)
# Bullseye: Debian 11 (32bit and 64bit)
# Buster:   Debian 10 (32bit)
# Stretch:  Debian 9  (32bit)

# prepare rtlsdr-ogn
if [ "$ARCH" -eq 64 ]; then
  echo
  echo "wrong platform for this script, exiting"
  echo
  exit
else
  wget http://download.glidernet.org/rpi-gpu/rtlsdr-ogn-bin-RPI-GPU-0.3.0.tgz
  tar xvf *.tgz
fi

cd rtlsdr-ogn || exit
sudo chown root gsm_scan ogn-rf rtlsdr-ogn
sudo chmod a+s gsm_scan ogn-rf rtlsdr-ogn
sudo mknod gpu_dev c 100 0

echo
echo "Please edit Template.conf, to set-up the receiver:"
echo "enter your ppm correction, GSM frequency for calibration, geographical position and APRS name"
echo
read -p "Press any key to continue"
sudo nano Template.conf

sudo wget http://download.glidernet.org/common/WW15MGH.DAC

# install rtlsdr-ogn service
sudo cp -v rtlsdr-ogn /etc/init.d/rtlsdr-ogn
sudo cp -v rtlsdr-ogn.conf /etc/rtlsdr-ogn.conf
sudo update-rc.d rtlsdr-ogn defaults

echo
read -t 1 -n 10000 discard
read -p "Reboot now? [y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo reboot
fi
