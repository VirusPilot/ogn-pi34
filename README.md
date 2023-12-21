# ogn-pi34 (ogn binary beta version 0.2.9 / Feb 14 2023)
- script `install-pi34.sh` to built an OGN station to feed the **Open Glider Network:** https://wiki.glidernet.org
- the alternative script `install-pi3-gpu.sh` makes use of the GPU on the Pi3 to reduce CPU workload (but only on 32bit and up to Rapsbian Buster platforms)
- Pi Zero 2W, Pi3 or Pi4 with **RasPiOS Lite** (32bit or 64bit) are supported
- Raspberry Pi Imager (https://www.raspberrypi.com/software/) is recommended
- latest 0.2.9 version enables **SDR autogain** to avoid crossmodulation
- latest 0.2.9 version support the following protocols:
  - FLARM
  - OGN
  - SafeSky
  - PilotAware
  - SPOT
  - Garmin InReach
  - Skymaster
  - FANET (paragliders)
  - Spidertracks
  - **ADS-L** (experimental)

## supported RasPiOS and Pi versions
- `rtlsdr-ogn-bin-arm64-0.2.9_debian_bullseye.tgz`: **64-bit** Debian 12,11,10 (bookworm, bullseye, buster), Pi Zero 2W, Pi3 or Pi4
- `rtlsdr-ogn-bin-ARM-0.2.9_raspbian_buster.tgz`: **32-bit** Debian 12,11,10 (bookworm, bullseye, buster), Pi Zero 2W, Pi3 or Pi4
- `rtlsdr-ogn-bin-ARM-0.2.9_raspbian_stretch.tgz`: **32-bit** Debian 9 (stretch), Pi Zero 2W or Pi3
- `rtlsdr-ogn-bin-RPI-GPU-0.2.9_raspbian_stretch.tgz`: **32-bit** Debian 9,10 (buster, stretch), Pi3 (using GPU)

## packages for x86 and x64 based thin-clients, please install them manually
- `rtlsdr-ogn-bin-x64-0.2.9_debian_bullseye.tgz`
- `rtlsdr-ogn-bin-x64-0.2.9_ubuntu_cosmic.tgz`
- `rtlsdr-ogn-bin-x86-0.2.9_debian_buster.tgz`

## prepare script for Pi3B, Pi4B or Pi Zero 2W:
- flash latest **RasPiOS Lite Image** (32bit or 64bit), using latest Raspberry Pi Imager with the following settings:
  - select appropriate hostname
  - enable ssh
  - enable user pi with password
  - configure WiFi (particularly important for Pi Zero 2W)
- boot and wait until your Pi is connected to your LAN or WiFi

## preparation of OGN credentials
During the setup process you will be asked to edit (using nano) `Template.conf` for which you should have the following credentials at hand:
- SDR device number (to avoid conflicts if you have multiple SDRs installed); alternatively if you know already the serial number of your SDR, you can use that to automatically select the appropriate SDR
- SDR ppm calibration (only required for non-TCXO SDRs), this can also be measured and modified accordingly post install if unknown
```
RF:
{
  Device   = 0;            # SDR selection by device index, can be verified with "sudo rtl_eeprom -d 0" or "-d 1", ...
  #DeviceSerial = "868";   # SDR selection by serial number (as an alternative)
  FreqCorr = 0;            # [ppm] "big" R820T sticks have 40-80ppm correction factors, measure it with gsm_scan
                           # SDRs with TCXO: have near zero frequency correction and you can ommit this parameter
};
```
- SDR autogain target range (adding MinNoise and MaxNoise values):
```
OGN:
{
  CenterFreq = 868.8;    # [MHz] with 868.8MHz and 2MHz bandwidth you can capture all systems: FLARM/OGN/FANET/PilotAware...
  Gain       =  50.0;    # [dB]  this is the startup gain, will be automatically adjusted
  MinNoise   =   2.0;    # default minimum allowed noise, you can ommit this parameter
  MaxNoise   =   8.0;    # default maximum allowed noise, you can ommit this parameter
};
```
- **important:** in case your OGN station is in an area with no GSM stations then the automatic gsm_scan should be deactivated by changing to `GSM.CenterFreq=0` (as an alternative you can ommit the entire GSM section for SDRs with TCXO):
```
GSM:                     # for frequency calibration based on GSM signals
{
  CenterFreq  =     0;   # [MHz] find the best GSM frequency with gsm_scan
  Gain        =  30.0;   # [dB]  RF input gain (beware that GSM signals are very strong !)
};
```
- **important:** GPS coordinates and altitude for your OGN station:
```
Position:
{ 
  Latitude   =   +48.0000; # [deg] Antenna coordinates
  Longitude  =    +9.0000; # [deg]
  Altitude   =        100; # [m]   Altitude above sea leavel
};
```
- APRS name (please remove the `#` in front of `Call` and change `SampleAPRSnameToChange` to your APRS callsign):
```
APRS:
{
  Call = "SampleAPRSnameToChange";      # APRS callsign (max. 9 characters)
                                        # Please refer to http://wiki.glidernet.org/receiver-naming-convention
};
```
- you can monitor your OGN receiver by visiting https://yourstation:8080 and https://yourstation:8081
- in case you plan to combine the OGN station with a dump1090 feeder, the following addition is necessary:
```
HTTP:
{
  Port = 8082;
};
```
- now you can monitor your OGN receiver by visiting https://yourstation:8082 and https://yourstation:8083
- your dump1090 station can be monitored by visiting https://yourstation:8080
## automatic setup (standard script)
- plug your SD card into the Pi, connect your Pi3 or Pi4 to LAN via Ethernet cable and boot (in case of Pi Zero 2W you may need to wait and check for successful WiFi connection)
- connect to your pi using ssh
```
sudo apt update
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh
```

## automatic setup (alternative script with GPU code for Pi3)
```
sudo apt update
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi3-gpu.sh
```

## please use these scripts with caution and ideally on a fresh 64bit RasPiOS Lite Image
if you intent to upgrade an older OGN version, you just have to replace two binaries: `ogn-rf` and `ogn-decode`, here are the required steps (Bullseye 64-bit version as an example):
- `mkdir temp`
- `tar xvf ogn-pi34/rtlsdr-ogn-bin-arm64-0.2.9_debian_bullseye.tgz -C ./temp`
- `cp ./temp/rtlsdr-ogn/ogn-* <your current rtlsdr-ogn folder>`
- `sudo service rtlsdr-ogn restart`
- `sudo service rtlsdr-ogn status` (to verify that the new version is running)

## post install modifications
### SDR ppm calibration (only required for non-TCXO SDRs)
- see https://github.com/glidernet/ogn-rf/blob/6d6cd8a15a5fbff122542401180ea7e58af9ed92/INSTALL#L42
### nightly reboot at 1 am
- execute the following: `sudo crontab -e` then add `0 1 * * * /sbin/reboot` and save 
