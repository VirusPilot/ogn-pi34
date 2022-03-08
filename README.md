# ogn-pi34 (armhf and arm64)
Script to built an OGN station on a Pi 2 Zero 2W, Pi3 or Pi4, based on RasPiOS Lite (armhf and arm64) and OGN version 0.2.9, flashing the latest images from here with etcher (arm64 is recommended):

- http://downloads.raspberrypi.org/raspios_lite_armhf/images/ (32bit, "armhf")
- http://downloads.raspberrypi.org/raspios_lite_arm64/images/ (64bit, "arm64")

After the successful flash, remove the SD card and plug it into your PC again to further prepare for the setup procedure:
- copy empty ssh file to /boot directory of the SD card
- optional for Pi3 and Pi4, **mandatory for Pi Zero 2W: create wpa_supplicant.conf**, using e.g. https://www.pistar.uk/wifi_builder.php (required to enable connecting to your local WiFi) and then copy wpa_supplicant.conf to /boot directory of the SD card

## preparation of OGN credentials
During the setup process you will be asked to edit (using nano) `Template.conf` for which you should have the following credentials at hand:
- SDR device number (to avoid conflicts if you have multiple SDRs installed); alternatively if you know already the serial number of your SDR, you can use that to automatically select the appropriate SDR
- SDR frequency correction [ppm] (this can also be measured and mofified accordingly post install if unknown)
```
RF:
{
  Device   = 0;            # Device index for OGN reception. E.g. check "sudo rtl_eeprom -d 0" or "-d 1", ...
  #DeviceSerial = "868";   # alternative
  FreqCorr = 0;            # [ppm] "big" R820T sticks have 40-80ppm correction factors, measure it with gsm_scan
}
```
- GPS coordinates and altitude for your OGN station, GeoidSepar needs to be disabled:
```
Position:
{ Latitude   =   +48.0000; # [deg] Antenna coordinates
  Longitude  =    +9.0000; # [deg]
  Altitude   =        100; # [m]   Altitude above sea leavel
} ;
```
- APRS name (please remove the `#` in front of `Call` and change `SampleAPRSnameToChange` to your APRS callsign):
```
APRS:
{ Call = "SampleAPRSnameToChange";      # APRS callsign (max. 9 characters)
                                        # Please refer to http://wiki.glidernet.org/receiver-naming-convention
} ;
```

## automatic setup
- plug your SD card into the Pi, connect your Pi3 or Pi4 to LAN via Ethernet cable and boot (in case of Pi Zero 2W you may need to wait and check for successful WiFi connection)
- ssh pi@raspberrypi.local (passwd: raspberry)
```
sudo apt update
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh
```
- reboot
## post install modifications
### GSM gain/frequency and ppm calibration
- see https://github.com/glidernet/ogn-rf/blob/6d6cd8a15a5fbff122542401180ea7e58af9ed92/INSTALL#L42
### OGN gain
- the SDR gain should be set such that the RF input noise is only a couple of dBs
