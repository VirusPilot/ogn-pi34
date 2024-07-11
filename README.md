# scripts to built a receiver station to feed the Open Glider Network
## supported platforms by these scripts:
- Bookworm (Debian 12): 64bit and 32bit
- Bullseye (Debian 11): 32bit (no RTL-SDR Blog V4 dongle support)
- for older RasPiOS versions please consider a manual update as described below
## details about the scripts
- standard script: `install-pi34.sh`
- alternative script: `install-pi34-adsb.sh`
  - requires a **second SDR**
  - installs https://github.com/VirusPilot/dump1090 in addition to feed Open Glider Network with ADS-B
  - ADS-B SDR adaptive gain and adaptive burst mode enabled (to prefer local traffic)
- Pi Zero 2W, Pi3, Pi4 or Pi5 are supported
- Raspberry Pi Imager (https://www.raspberrypi.com/software/) is recommended
- latest 0.3.2 version enables **SDR autogain** to avoid crossmodulation
- latest 0.3.2 version supports the following protocols:
  - ADS-B (requires `dump1090-fa` runing on the same receiver but on a **second SDR**)
  - FLARM
  - OGN
  - SafeSky
  - PilotAware
  - SPOT
  - Garmin InReach
  - Skymaster
  - FANET (paragliders)
  - Spidertracks
  - ADS-L
  - ...

## packages for manual update of legacy platforms
- https://github.com/VirusPilot/ogn-pi34/raw/master/rtlsdr-ogn-bin-arm64-0.3.2_Bullseye.tgz
- https://github.com/VirusPilot/ogn-pi34/raw/master/rtlsdr-ogn-bin-ARM-0.3.2_Jessie.tgz
- https://github.com/VirusPilot/ogn-pi34/raw/master/rtlsdr-ogn-bin-ARM-0.3.2_Jessie_JPEG.tgz
- https://github.com/VirusPilot/ogn-pi34/raw/master/rtlsdr-ogn-bin-RPI-GPU-0.3.2_Jessie.tgz
- https://github.com/VirusPilot/ogn-pi34/raw/master/rtlsdr-ogn-bin-RPI-GPU-0.3.2_Jessie_JPEG.tgz
- https://github.com/VirusPilot/ogn-pi34/raw/master/rtlsdr-ogn-bin-x86-0.3.2_Buster.tgz

## prepare script for Pi3, Pi4, Pi5 or Pi Zero 2W:
- flash **latest RasPiOS Lite Image** (32bit or 64bit), using latest Raspberry Pi Imager with the following settings:
  - select appropriate hostname
  - enable ssh
  - enable user pi with password
  - configure WiFi (particularly important for Pi Zero 2W)
- boot and wait until your Pi is connected to your LAN or WiFi

## preparation of credentials
During the setup process you will be automatically asked to edit `Template.conf` and potentially `dump1090-fa` for which you should have the following credentials at hand:
- SDR index numbers or SDR serial numbers (SN) for both the OGN and ADS-B SDRs
- SDR ppm calibration (only required for non-TCXO SDRs), this can also be measured and modified accordingly post install if unknown
- OGN station name, e.g. your local airport ICAO code (max. 9 characters), please refer to http://wiki.glidernet.org/receiver-naming-convention
- station coordinates and altitude for both the OGN and ADS-B configuration file

SDR selection and ppm correction:
```
RF:
{
  Device   = 0;            # device selection based on SDR index number, please doublecheck post-install using "rtl_test"
  #DeviceSerial = "868";   # alternative device selection based on SDR serial number (SN), please doublecheck post-install using "rtl_test"
  FreqCorr = 0;            # [ppm] SDR correction factor, newer sticks have a TCXO so no correction required
  SampleRate = 2.0;        # [MHz] 1.0 or 2.0MHz, 2MHz is required to captue PilotAware
  BiasTee  = 0;            # just a safeguard
};
```
In case your OGN station is in an area with no GSM stations then the automatic gsm_scan should be deactivated by changing to `GSM.CenterFreq=0` (as an alternative you can ommit the entire GSM section for SDRs with TCXO):
```
GSM:                  # for frequency calibration based on GSM signals
{                     # you can ommit the whole GSM section for sticks with TCXO
  CenterFreq  =    0; # [MHz] you may enter the GSM frequency that you found with gsm_scan but ONLY if you have GSM stations nearby
  Gain        = 25.0; # [dB]  RF input gain (beware that GSM signals are very strong)
};
```
GPS coordinates and altitude for your OGN station:
```
Position:
{ 
  Latitude   =   +48.0000; # [deg] please put in the appropriate latitude for your OGN station antenna
  Longitude  =   +10.0000; # [deg] please put in the appropriate longitude for your OGN station antenna
  Altitude   =        500; # [m]   altitude AMSL, please put in the appropriate altitude for your OGN station antenna
};
```
Required configuration for feeding Open Glider Network with ADS-B traffic:
```
ADSB:                      # feeding Open Glider Network with ADS-B traffic
{
  AVR = "localhost:30002"; # disable this line if you DO NOT WANT to feed Open Glider Network with ADS-B traffic
  MaxAlt = 18000;          # [ft] default maximum altitude, feel free to increase but this will potentially increase your internet traffic
};
```
Replace <NewOGNrx> with your actual APRS callsign, please refer to http://wiki.glidernet.org/receiver-naming-convention:
```
APRS:
{
  #Call = "NewOGNrx";          # enable this line and replace <NewOGNrx> with your actual APRS callsign, e.g. your local airport ICAO code (max. 9 characters)
                               # please refer to http://wiki.glidernet.org/receiver-naming-convention
};
```
In case you plan to combine the OGN station with a dump1090-fa feeder (like in the alternative install script below), the following section is required:
```
HTTP:           # this section is required to be able to monitor the different status pages of your receiver
{               # e.g. http://raspberrypi:8080 for monitoring ADS-B traffic
  Port = 8082;  # e.g. http://raspberrypi:8082 for monitoring the RTLSDR OGN RF processor status page
};              # e.g. http://raspberrypi:8083 for monitoring the RTLSDR OGN demodulator and decoder status page
```

## automatic setup (standard script)
- plug your SD card into the Pi, connect your Pi3, Pi4 or Pi5 to LAN via Ethernet cable and boot (in case of Pi Zero 2W you may need to wait and check for successful WiFi connection)
- connect to your pi using ssh
```
sudo apt update
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh
```

## automatic setup (alternative script that installs dump1090-fa in addition)
- based on https://github.com/VirusPilot/dump1090
```
sudo apt update
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34-adsb.sh
```

## steps to manually upgrade legacy platforms
`ogn-rf` and `ogn-decode` need to be replaced, here are the required steps:
- `mkdir temp`
- `cd temp`
- find out whether you are running 32bit or 64bit with `getconf LONG_BIT`
- to update a 64bit RasPiOS Bullseye receiver:
  - `wget https://github.com/VirusPilot/ogn-pi34/raw/master/rtlsdr-ogn-bin-arm64-0.3.2_Bullseye.tgz`
- to update a 32bit RasPiOS Bullseye receiver:
  - `wget http://download.glidernet.org/arm/rtlsdr-ogn-bin-ARM-0.3.2.tgz`
- `tar xvf *.tgz`
- `cp -f rtlsdr-ogn/ogn-* <your_current_rtlsdr-ogn_folder>`
- if you have a dump1090-fa instance already running and want to feed OGN with ADS-B traffic, you need to add the following section to your OGN configuration file:
  ```
  ADSB:
  {
    AVR = "localhost:30002";
    MaxAlt = 18000;
  };
  ```
- `cd <your_current_rtlsdr-ogn_folder>`
- `sudo chown root gsm_scan ogn-rf rtlsdr-ogn`
- `sudo chmod a+s gsm_scan ogn-rf rtlsdr-ogn`
- `sudo service rtlsdr-ogn restart` or `sudo reboot`
- `sudo service rtlsdr-ogn status` (to verify that the new version is running)

## post install modifications
### remove Raspberry Pi USB power supply limitation
- it might be necessary to remove the Raspberry Pi3 or Pi4 USB power supply limitation by adding `max_usb_current=1` (Pi5: `usb_max_current_enable=1`) to `/boot/config.txt` (`/boot/firmware/config.txt` in case of Bookworm)
### SDR ppm calibration (only required for non-TCXO SDRs)
- see https://github.com/glidernet/ogn-rf/blob/6d6cd8a15a5fbff122542401180ea7e58af9ed92/INSTALL#L42
### optional: nightly reboot at 1 am
- execute the following: `sudo crontab -e` then add `0 1 * * * /sbin/reboot` and save
### optional: disable swapfile
- `sudo systemctl disable dphys-swapfile`
- `sudo apt purge dphys-swapfile -y`
- `sudo apt autoremove -y`
