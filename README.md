# ogn-pi34 install scripts
- script `install-pi34.sh` to built an OGN station to feed the **Open Glider Network:** https://wiki.glidernet.org
- the alternative script `install-pi34-adsb.sh` installs my dump1090-fa fork in addition (with **SDR autogain** enabled to prefer local traffic) to feed Open Glider Network with ADS-B
- the alternative script `install-pi3-gpu.sh` makes use of the GPU on the Pi3 to reduce CPU workload (but only on 32bit platforms)
- Pi Zero 2W, Pi3 or Pi4 with **RasPiOS Lite** (32bit or 64bit) are supported
- Raspberry Pi Imager (https://www.raspberrypi.com/software/) is recommended
- latest 0.3.0 version enables **SDR autogain** to avoid crossmodulation
- latest 0.3.0 version support the following protocols:
  - WIP: ADS-B (requires `dump1090-fa` runing on the same receiver)
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

## supported RasPiOS and Pi versions
- **64-bit**: only Debian 12 Bookworm or newer on Pi Zero 2W, Pi3 or Pi4
- **32-bit**: all RasPiOS versions on Pi Zero 2W, Pi3 or Pi4
- **32-bit (RPI-GPU)**: RasPiOS up to Buster on Pi3 (using GPU)

## prepare script for Pi3B, Pi4B or Pi Zero 2W:
- flash latest **RasPiOS Lite Image** (32bit or 64bit), using latest Raspberry Pi Imager with the following settings:
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
Replace <station> with your actual APRS callsign, please refer to http://wiki.glidernet.org/receiver-naming-convention:
```
APRS:
{
    Call = "station"; # replace <station> with your actual APRS callsign, e.g. your local airport ICAO code (max. 9 characters)
};
```
In case you plan to combine the OGN station with a dump1090-fa feeder (like in the alternative install script below), the following section is required:
```
HTTP:           # this section is required to be able to monitor the different status pages of your receiver
{               # e.g. http://raspberrypi:8080 for monitoring all traffic consolidated on a single map
  Port = 8082;  # e.g. http://raspberrypi:8082 for monitoring the RTLSDR OGN RF processor status page
};              # e.g. http://raspberrypi:8083 for monitoring the RTLSDR OGN demodulator and decoder status page
```

## automatic setup (standard script)
- plug your SD card into the Pi, connect your Pi3 or Pi4 to LAN via Ethernet cable and boot (in case of Pi Zero 2W you may need to wait and check for successful WiFi connection)
- connect to your pi using ssh
```
sudo apt update
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh
```

## automatic setup (alternative script that installs dump1090-fa in addition)
```
sudo apt update
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34-adsb.sh
```

## automatic setup (alternative script with GPU code for Pi3, only on 32bit RasPiOS up to Buster)
```
sudo apt update
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi3-gpu.sh
```

## steps to upgrade a 32bit RasPiOS Bullseye receiver
`ogn-rf` and `ogn-decode` need to be replaced, here are the required steps:
- `mkdir temp`
- `wget http://download.glidernet.org/arm64/rtlsdr-ogn-bin-ARM-0.3.0.tgz`
- `tar xvf rtlsdr-ogn-bin-ARM-0.3.0.tgz -C ./temp`
- `cp -f ./temp/rtlsdr-ogn/ogn-* <your current rtlsdr-ogn folder>`
- `cd <your current rtlsdr-ogn folder>`
- `sudo chown root gsm_scan ogn-rf rtlsdr-ogn`
- `sudo chmod a+s gsm_scan ogn-rf rtlsdr-ogn`
- `sudo service rtlsdr-ogn restart`
- `sudo service rtlsdr-ogn status` (to verify that the new version is running)

## post install modifications
### SDR ppm calibration (only required for non-TCXO SDRs)
- see https://github.com/glidernet/ogn-rf/blob/6d6cd8a15a5fbff122542401180ea7e58af9ed92/INSTALL#L42
### optional: nightly reboot at 1 am
- execute the following: `sudo crontab -e` then add `0 1 * * * /sbin/reboot` and save
### optional: disable swapfile
- `sudo systemctl disable dphys-swapfile`
- `sudo apt purge dphys-swapfile -y`
- `sudo apt autoremove -y`
