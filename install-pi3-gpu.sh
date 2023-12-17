#!/bin/bash
#set -x

sudo apt install git build-essential libconfig9 libfftw3-bin libtool libusb-1.0-0-dev lynx ntp ntpdate procserv telnet cmake -y

# install librtlsdr from source
cd || exit
git clone https://github.com/VirusPilot/rtl-sdr.git
cd rtl-sdr || exit
mkdir build
cd build || exit
cmake ../ -DDETACH_KERNEL_DRIVER=ON -DINSTALL_UDEV_RULES=ON
make
sudo make install
sudo ldconfig
cd || exit

# prevent kernel modules claiming use of the USB DVB-T dongle
echo blacklist rtl2832 | sudo tee /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist r820t | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist rtl2830 | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist dvb_usb_rtl28xxu | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist dvb_usb_v2 | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist rtl8xxxu | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf

ARCH=$(getconf LONG_BIT)
DIST=$(lsb_release -r -s)
if [ "$ARCH" -eq 64 ] || [ "$DIST" -gt 10 ]; then
  echo
  echo "wrong platform for this script, exiting"
  echo
  exit
else
  echo
  echo "installing Stretch 32bit version for Pi3 GPU on" "$ARCH""bit" "Debian" "$DIST"
  read -p "Press any key to continue"
  echo
  tar xvf ogn-pi34/rtlsdr-ogn-bin-RPI-GPU-0.2.9_raspbian_stretch.tgz
fi

cd rtlsdr-ogn || exit
sudo chown root gsm_scan
sudo chmod a+s gsm_scan
sudo chown root ogn-rf
sudo chmod a+s ogn-rf
sudo chown root rtlsdr-ogn
sudo chmod a+s rtlsdr-ogn
sudo mknod gpu_dev c 100 0

echo
echo "Please edit Template.conf, to set-up the receiver:"
echo "enter your ppm correction, GSM frequency for calibration, geographical position and APRS name"
echo
read -p "Press any key to continue"
sudo nano Template.conf

sudo wget http://download.glidernet.org/common/WW15MGH.DAC

# install rtlsdr-ogn to run OGN receiver as a service
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
