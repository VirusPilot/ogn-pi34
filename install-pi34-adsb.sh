#!/bin/bash
#set -x

sudo apt update
sudo apt install git lighttpd build-essential fakeroot debhelper pkg-config libncurses5-dev libfftw3-bin libusb-1.0-0-dev lynx ntp ntpdate procserv telnet -y

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
if [ "$ARCH" -eq 64 ] && [ "$DIST" -ge 11 ]; then
  tar xvf ogn-pi34/rtlsdr-ogn-bin-arm64-0.2.9_debian_bullseye.tgz
else
  if [ "$ARCH" -eq 32 ] && [ "$DIST" -ge 10 ]; then
    tar xvf ogn-pi34/rtlsdr-ogn-bin-ARM-0.2.9_raspbian_buster.tgz
  else
    tar xvf ogn-pi34/rtlsdr-ogn-bin-ARM-0.2.9_raspbian_stretch.tgz
  fi
fi

cd rtlsdr-ogn
sudo chown root gsm_scan ogn-rf ogn-rf-soapysdr rtlsdr-ogn
sudo chmod a+s gsm_scan ogn-rf ogn-rf-soapysdr rtlsdr-ogn
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

# install dump1090-fa service
cd
git clone https://github.com/VirusPilot/dump1090.git
cd dump1090
sudo dpkg-buildpackage -b --no-sign --build-profiles=custom,rtlsdr
cd ..
sudo dpkg -i dump1090-fa_*.deb
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
