# ogn-pi4
Script to built an OGN server on a Pi4 (Pi3) based on a fresh Raspbian Buster Lite image
## Automatic Setup
```
sudo apt update
sudo apt full-upgrade
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi4.git
cp -f ogn-pi4/install.sh .
./install.sh
```
## change from Ethernet to WiFi connection
```
sudo raspi-config
```
