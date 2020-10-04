#!/bin/bash
#set -x

sudo timedatectl set-timezone Europe/Berlin

sudo apt install build-essential -y
sudo apt install cmake -y
sudo apt install libconfig9 -y
sudo apt install libfftw3-bin -y
sudo apt install libjpeg8 -y
sudo apt install libtool -y
sudo apt install libusb-1.0-0-dev -y
sudo apt install lynx -y
sudo apt install ntp -y
sudo apt install ntpdate -y
sudo apt install procserv -y
sudo apt install telnet -y

# install librtlsdr
cd
rm -rf rtl-sdr
git clone https://github.com/osmocom/rtl-sdr.git
cd rtl-sdr
mkdir build
cd build
cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON
make
sudo make install
sudo ldconfig

# prevent kernel modules claiming use of the USB DVB-T dongle
echo blacklist rtl2832 | sudo tee /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist r820t | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist rtl2830 | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist dvb_usb_rtl28xxu | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf

# download and unpack version 0.2.8
cd
wget http://download.glidernet.org/arm/rtlsdr-ogn-bin-ARM-0.2.8.tgz
tar xvzf *.tgz
rm *.tgz

cd rtlsdr-ogn
sudo chown root gsm_scan
sudo chmod a+s gsm_scan
sudo chown root ogn-rf
sudo chmod a+s  ogn-rf
sudo chown root rtlsdr-ogn
sudo chmod a+s  rtlsdr-ogn
sudo mknod gpu_dev c 100 0

cp -f Template.conf myPlace.conf
# - edit myPlace.conf, to set-up the receiver:
# - enter your crystal correction
# - GSM frequency for calibration, geographical position, APRS name
sudo nano myPlace.conf

sudo wget --no-check-certificate http://earth-info.nga.mil/GandG/wgs84/gravitymod/egm96/binary/WW15MGH.DAC

# install rtlsdr-ogn to run OGN receiver as a service
sudo cp -v rtlsdr-ogn /etc/init.d/rtlsdr-ogn
sudo cp -v rtlsdr-ogn.conf /etc/rtlsdr-ogn.conf
sudo update-rc.d rtlsdr-ogn defaults

# Update /etc/rtlsdr-ogn.conf according to name of your configuration file
# by replacing SampleConfigurationFileNameToChange.conf by the name of your config file (e.g. myPlace.conf)
# and pi with your actual username
sudo nano /etc/rtlsdr-ogn.conf

echo
read -t 1 -n 10000 discard
read -p "Reboot now? [y/n]"
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo reboot
fi
