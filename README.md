## Introduction

Bash script to automatically install and configure an openHAB system (Z-Wave and HABmin preconfigured)

## Features

The script installs the following packages:

- Java 8 (latest version from repository)
- openhab-runtime (1.8.3)
- Z-Wave binding (1.10.0-SNAPSHOT)
- Udev rule for Aeon Labs Z-Stick Gen2 and Gen5
- HABmin (1.7.0-SNAPSHOT)

## Installation

The script has been succesfully tested on a Raspberry Pi, but it should work on any Debian based (Ubuntu) distribution.

wget https://raw.githubusercontent.com/Tknika/openhab-zwave-installation-script/master/install.sh

chmod +x install.sh

sudo ./install.sh

Enjoy!
