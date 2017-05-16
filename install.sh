#!/bin/bash
# Author: Aitor Iturrioz, 16 May 2017
# Desciption: Bash script to automatically install and configure an openHAB system with the Z-Wave binding
#             and HABmin already preconfigured.


# Make sure the script is executed as root
if [[ $EUID -ne 0 ]]; then
   echo -e "This script must be run as root" 1>&2
   exit 1
fi

# Make sure that we haven't executed the script
if [ -f "OPENHAB_DONE" ]
then
    echo -e "You have already executed the program"
    exit
fi



##### Java installation #####
# Check if java in installed
if java -version 2>&1 >/dev/null | grep -q "java version" ; then
    echo -e 'Java is available on the system\n'
else
    echo -e 'Java is not available, installing it... (wait)'
    apt-get install -y oracle-java8-jdk > /dev/null 2>&1
    echo -e "Java correctly installed\n"
fi



##### openHAB installation #####
echo -e "Installing openHAB... (wait)"

# Download repository key
wget -qO - 'https://bintray.com/user/downloadSubjectPublicKey?username=openhab' | sudo apt-key add - > /dev/null 2>&1

# Add openHAB repository to apt source list
echo "deb http://dl.bintray.com/openhab/apt-repo stable main" | sudo tee /etc/apt/sources.list.d/openhab.list

# Resynchronize the package index
apt-get update > /dev/null 2>&1

# Install openhab-runtime
apt-get install -y openhab-runtime > /dev/null 2>&1

# Make openhab start at boot time
systemctl daemon-reload > /dev/null 2>&1
systemctl enable openhab > /dev/null 2>&1

echo -e "openHAB correctly installed\n"



##### openHAB configuration #####
echo -e "Configuring openHAB... (wait)"

# Edit startup file (/etc/default/openhab)
debug_line='DEBUG=no'
debug_line_new='DEBUG=yes'
sed -i "s@$debug_line@$debug_line_new@g" /etc/default/openhab > /dev/null 2>&1

# Make a copy of the openhab_default.cfg file
cp /etc/openhab/configurations/openhab_default.cfg /etc/openhab/configurations/openhab.cfg

# Change the scan refresh times
file_path='/etc/openhab/configurations/openhab.cfg'
sitemaps_refresh='sitemaps=10,sitemap'
sitemaps_refresh_new='sitemaps=15,sitemap'
rules_refresh='rules=10,rules'
rules_refresh_new='rules=30,rules'
scripts_refresh='scripts=10,script'
scripts_refresh_new='scripts=20,script'
persistence_refresh='persistence=10,persist'
persistence_refresh_new='persistence=12,persist'
sed -i "s@$sitemaps_refresh@$sitemaps_refresh_new@g" $file_path > /dev/null 2>&1
sed -i "s@$rules_refresh@$rules_refresh_new@g" $file_path > /dev/null 2>&1
sed -i "s@$scripts_refresh@$scripts_refresh_new@g" $file_path > /dev/null 2>&1
sed -i "s@$persistence_refresh@$persistence_refresh_new@g" $file_path > /dev/null 2>&1

# Add the openhab user to the 'dialout' group
usermod -a -G dialout openhab > /dev/null 2>&1

echo -e "openHAB correctly configured\n"


##### Z-Wave snapshot binding installation #####
echo -e "Installing and configuring Z-Wave binding... (wait)"

# Download the .jar file
url=https://openhab.ci.cloudbees.com/job/openHAB1-Addons/lastSuccessfulBuild/artifact/bundles/binding/org.openhab.binding.zwave/target/org.openhab.binding.zwave-1.10.0-SNAPSHOT.jar
destination_folder='/usr/share/openhab/addons/'
wget $url -P $destination_folder > /dev/null 2>&1



##### Z-Wave binding configuration #####
# Udev rule installation
udev_rule_path='/etc/udev/rules.d/50-usb-serial.rules'
z_wave_usb_identifiers='SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="USBzwave", GROUP="dialout", MODE="0666"\nSUBSYSTEM=="tty", ATTRS{idVendor}=="0658", ATTRS{idProduct}=="0200", SYMLINK+="USBzwave", GROUP="dialout", MODE="0666"'
echo -e $z_wave_usb_identifiers > $udev_rule_path

# Edit the openhab.cfg file
file_path='/etc/openhab/configurations/openhab.cfg'
zwave_port='#zwave:port='
zwave_port_new='zwave:port=/dev/USBzwave'
sed -i "s@$zwave_port@$zwave_port_new@g" $file_path > /dev/null 2>&1

# Edit the startup file (/etc/default/openhab)
file_path='/etc/default/openhab'
java_args='JAVA_ARGS='
java_args_new='JAVA_ARGS=-Dgnu.io.rxtx.SerialPorts=/dev/USBzwave'
sed -i "s@$java_args@$java_args_new@g" $file_path > /dev/null 2>&1

echo -e "Z-Wave binding correctly installed and configured\n"


##### HABmin installation #####
echo -e "Installing HABmin... (wait)"

# Download the .zip file
url='https://github.com/cdjackson/HABmin/archive/master.zip'
destination_folder='/usr/share/openhab/webapps/'
wget $url -P $destination_folder > /dev/null 2>&1

# Unzip de file
unzip /usr/share/openhab/webapps/master.zip -d $destination_folder > /dev/null 2>&1

# Change the folder name
mv /usr/share/openhab/webapps/HABmin-master/ /usr/share/openhab/webapps/habmin

# Move the .jar file to the addons folder
mv /usr/share/openhab/webapps/habmin/addons/org.openhab.io.habmin*.jar /usr/share/openhab/addons/

# Delete garbage files
rm -rf /usr/share/openhab/webapps/habmin/addons > /dev/null 2>&1
rm /usr/share/openhab/webapps/master.zip > /dev/null 2>&1

echo -e "HABmin correctly installed\n"



##### Write an indicator that the script has been executed #####
echo -e "" > OPENHAB_DONE



##### Restart the system #####
echo -e "Rebooting the system\n"
reboot
