#!/bin/bash
#set -x

sudo apt update
sudo apt install librtlsdr-dev librtlsdr0 rtl-sdr git cmake lighttpd build-essential fakeroot pkg-config libncurses5-dev libfftw3-bin libusb-1.0-0-dev lynx chrony procserv telnet netcat-traditional debhelper -y
sudo apt autoremove -y

# legacy DVB-T TV drivers need to be properly blacklisted (e.g. they will activate the bias tee by default)
echo 'blacklist dvb_usb_rtl28xxu' | sudo tee --append /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

# install rtlsdr-ogn
ARCH=$(uname -m)          # linux kernel architecture
DIST=$(lsb_release -r -s) # linux OS release numer
case "${ARCH}_${DIST}" in
  aarch64_13|arm64_13)    # 64bit Debian 13 Trixie (aarch64/arm64 platform)
    echo
    echo "installing OGN v0.3.3 (January 2026 version) on 64bit Debian 13 Trixie (aarch64/arm64 platform)"
    echo "press Return to continue or Ctr-C to abort"
    read -r
    tar xvf ogn-pi34/rtlsdr-ogn-bin-arm64-0.3.3_Trixie.tgz
    ;;
  aarch64_12|arm64_12)    # 64bit Debian 12 Bookworm (aarch64/arm64 platform)
    echo
    echo "installing OGN v0.3.2 (March 2024 version) on 64bit Debian 12 Bookworm (aarch64/arm64 platform)"
    echo "press Return to continue or Ctr-C to abort"
    read -r
    wget http://download.glidernet.org/arm64/rtlsdr-ogn-bin-arm64-0.3.2.tgz
    tar xvf *.tgz
    rm rtlsdr-ogn-bin-arm64-0.3.2.tgz
    ;;
  aarch64_11|arm64_11)    # 64bit Debian 11 Bullseye (aarch64/arm64 platform)
    echo
    echo "installing OGN v0.3.2 (March 2024 version) on 64bit Debian 11 Bullseye (aarch64/arm64 platform)"
    echo "press Return to continue or Ctr-C to abort"
    read -r
    tar xvf ogn-pi34/rtlsdr-ogn-bin-arm64-0.3.2_Bullseye.tgz
    ;;
  armv7l_11|armv6l_11)    # 32bit Debian 11 Bullseye (armv7l/armv6l platform)
    echo
    echo "installing OGN v0.3.2 (March 2024 version) on 32bit Debian 11 Bullseye (armv7l/armv6l platform)"
    echo "press Return to continue or Ctr-C to abort"
    read -r
    wget http://download.glidernet.org/arm/rtlsdr-ogn-bin-ARM-0.3.2.tgz
    tar xvf *.tgz
    rm rtlsdr-ogn-bin-ARM-0.3.2.tgz
    ;;
  x86_64_22.*|x86_64_23.*|x86_64_24.*|x86_64_25.*|x86_64_26.*|x86_64_12|x86_64_13)
    echo
    echo "installing OGN v0.3.3 (January 2026 version) on 64bit Linux (x86_64 Ubuntu or Debian) is not supported"
    echo "please consider using the related docker version or do a manual install"
    echo "press Return to exit"
    read -r
    exit 1
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
echo "enter your ppm correction, GSM frequency for calibration, geographical position and APRS name"
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
sudo systemctl restart dump1090-fa
