#!/bin/bash
#set -x

sudo apt update
sudo apt install git cmake libfftw3-bin libusb-1.0-0-dev lynx ntp ntpdate procserv telnet -y
sudo apt install debhelper -y

ARCH=$(getconf LONG_BIT)
DIST=$(lsb_release -r -s)

# install librtlsdr from http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr
# if [ $ARCH -eq 64 ] && [ "$DIST" -eq 12 ]; then
#     wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr0_2.0.2-2+b1_arm64.deb
#     wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr-dev_2.0.2-2+b1_arm64.deb
#     wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/rtl-sdr_2.0.2-2+b1_arm64.deb
# fi
# if [ $ARCH -eq 32 ] && [ "$DIST" -eq 12 ]; then # no RTL-SDR Blog V4 dongle support
#     wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr0_0.6.0-4_armhf.deb
#     wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr-dev_0.6.0-4_armhf.deb
#     wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/rtl-sdr_0.6.0-4_armhf.deb
# fi 
# if [ $ARCH -eq 64 ] && [ "$DIST" -eq 11 ]; then # no RTL-SDR Blog V4 dongle support
#     wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr0_0.6.0-4_arm64.deb
#     wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr-dev_0.6.0-4_arm64.deb
#     wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/rtl-sdr_0.6.0-4_arm64.deb
# fi
# if [ $ARCH -eq 32 ] && [ "$DIST" -eq 11 ]; then # no RTL-SDR Blog V4 dongle support
#     wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr0_0.6.0-4_armhf.deb
#     wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr-dev_0.6.0-4_armhf.deb
#     wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/rtl-sdr_0.6.0-4_armhf.deb
# fi
# sudo dpkg -i *.deb
# rm -f *.deb
# sudo ldconfig

# compile and install librtlsdr from https://github.com/osmocom/rtl-sdr
cd
git clone https://github.com/osmocom/rtl-sdr
cd rtl-sdr
mkdir build
cd build
cmake ../ -DDETACH_KERNEL_DRIVER=ON -DINSTALL_UDEV_RULES=ON
make
sudo make install
sudo ldconfig
cd

echo blacklist rtl2832 | sudo tee /etc/modprobe.d/rtl-sdr-blacklist.conf
echo blacklist r820t | sudo tee -a /etc/modprobe.d/rtl-sdr-blacklist.conf
echo blacklist rtl2830 | sudo tee -a /etc/modprobe.d/rtl-sdr-blacklist.conf
echo blacklist dvb_usb_rtl28xxu | sudo tee -a /etc/modprobe.d/rtl-sdr-blacklist.conf
echo blacklist dvb_usb_v2 | sudo tee -a /etc/modprobe.d/rtl-sdr-blacklist.conf
echo blacklist rtl8xxxu | sudo tee -a /etc/modprobe.d/rtl-sdr-blacklist.conf

# prepare rtlsdr-ogn
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
# sudo mknod gpu_dev c 100 0

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

echo
read -t 1 -n 10000 discard
read -p "Reboot now? [y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo reboot
fi
