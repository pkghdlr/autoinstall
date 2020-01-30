## autoinstall

This script can be used to install/remove packages, enable services and copy
files on your system typically to quickly set it up after an OS installation
or to bulk customize it.

Currently supported Linux Distro:
* Arch Linux
* Fedora Red Hat
* Ubuntu/Debian (UNTESTED)

## Usage

__Usage:__
└──╼ $ ./autoinstall.sh [-h|-v|-d|-V|-i [file]] configuration file

__OPTIONs:__

* -i     file: import data according to file.
* -d     Dry run. Echoes commands, no actual modification done.
* -v       Verbose mode.
* -h       Print help message.
* -V       Print version.


### Configuration file example:
---- configuration.conf ----
##
#This is the configuration file for ./autoinstall.sh script, use it to<br>
#configure: Packages to be installed and services to be enabled.<br>
#Each line format has to be:<br>
#NAME;space seprated values<br>
#TEST;qupzilla midori<br>
#<br>
#Use the key word SERVICE to identify services to be started.<br>
#SERVICE;nfs-kernel-server<br>
##<br>
<br>
\## REMOVE ##<br>
CLEANING;gbd<br>
<br>
\## PACKAGES to be installed<br>
SYSTEM;acpi alsa-plugin alsa-utils cmake gcc ifuse intel-ucode lightdm network-manager-applet wget xorg xfce4<br>
WEB;openssh thunderbird firefox nfs-utils<br>
EXTRA;mousepad libreoffice gcalculator xarchiver evince<br>
ADVANCED;vim jre8-openjdk-headless lightdm-webkit2-greeter audacity virtualbox<br>
MEDIA;clementine vlc youtube-dl kodi gst-plugins-good gst-plugins-ugly qt-gstreamer gst-plugins-bad<br>
<br>
\## SERVICES<br>
SERVICE;NetworkManager lightdm<br>

This is an example of file parsed with the -i option:

 ---- sys_cfg.txt---- <br>
    # This is a comment<br>
    .vimrc;/home/tt/<br>
    .bash_aliases;/home/tt/<br>
    #This is a comment<br>

----<br>
Before finishing the script will search for .vimrc file and copy it into /home/tt.


EXAMPLES:
The following run using the configuration.conf file in
verbose mode, copying data as specified in sys_cfg.txt.

./autoinstall.sh -v -i sys_cfg.txt configuration.conf
