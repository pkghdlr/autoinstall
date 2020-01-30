#!/bin/bash

# CONST
VERSION=19.10.28.1.4
TRUE=0
FALSE=1
CFG_NAME=

# VARs
is_online_try=2
is_config=$FALSE

cf=
pkg_mngr_install="pacman -S --noconfirm"
pkg_mngr_remove="pacman -Rsdu --noconfirm"
pkg_mngr_update="pacman -Syyu"
dry_run=$FALSE
verbose=$FALSE

## COLORS
#green='\e[0;32m'
#NC='\e[0m' #No Color
#bold=`tput bold`
#normal=`tput sgr0`

export BLUE='\033[1;94m'
export GREEN='\033[1;92m'
export RED='\033[1;91m'
export RESETCOLOR='\033[1;00m'

usage()
{
#/usr/bin/cat <<- _EOF_
echo -e "
Usage:
$RED└──╼ \$$GREEN"" $0 $RED[$GREEN""-h$RED|$GREEN""-v$RED|$GREEN""-d$RED|$GREEN""-V$RED|$GREEN""-i"" [file]$RED]$GREEN configuration file

Version: $RED $VERSION $RESETCOLOR

This script can be used to install/remove packages, enable services and copy
files on your system typically to quickly set it up after an OS installation
or to bulk customize your system.
Currently supported Linux Distro:
  Arch Linux
  Fedora Red Hat
  Ubuntu/Debian

OPTIONs:

$RED-i      $GREEN file: import data according to file.
$RED-d      $GREEN Dry run. Echoes commands, no actual modification done.
$RED-v      $GREEN Verbose mode.
$RED-h      $GREEN Print help message.
$RED-V      $GREEN Print version.

$RESETCOLOR
Configuration file example:
---- configuration.conf ----
##
# This is the configuration file for $0 script, use it to
# configure: Packages to be installed and services to be enabled.
# Each line format has to be:
# NAME;space seprated values
# TEST;qupzilla midori
#
# Use the key word SERVICE to identify services to be started.
# SERVICE;nfs-kernel-server
##

## REMOVE ##
REMOVE;gbd

## PACKAGES to be installed
SYSTEM;acpi alsa-plugin alsa-utils cmake gcc ifuse intel-ucode lightdm network-manager-applet wget xorg xfce4
WEB;openssh thunderbird firefox nfs-utils
EXTRA;mousepad libreoffice gcalculator xarchiver evince
ADVANCED;vim jre8-openjdk-headless lightdm-webkit2-greeter audacity virtualbox
MEDIA;clementine vlc youtube-dl kodi gst-plugins-good gst-plugins-ugly qt-gstreamer gst-plugins-bad

## SERVICES
SERVICE;NetworkManager lightdm

--------

This is an example of file parsed with the -i option:

$RED ---- sys_cfg.txt---- $RESETCOLOR
    # This is a comment
    .vimrc;/home/tt/
    .bash_aliases;/home/tt/
    #This is a comment

----
Before finishing the script will search for .vimrc file and copy it into /home/tt.

$BLUE
EXAMPLES:$RESETCOLOR
The following run using the configuration.conf file in
verbose mode, copying data as specified in sys_cfg.txt.

$0 -v -i sys_cfg.txt configuration.conf

$BLUE
CREDITS:$RESETCOLOR
pkghdlr

" >&2

}
## This function gets info on the system os type

get_pks_manager() {
    # os_type=$(/usr/bin/cat /etc/issue | cut -d " " -f1)
    os_type=$(. /etc/os-release; echo $ID)
    echo -e "$GREEN""[i] You're running a $os_type machine."
    case $os_type in
        "arch")
            pkg_mngr_install="pacman -S --noconfirm"
            pkg_mngr_remove="pacman -Rsdu --noconfirm"
            pkg_mngr_update="pacman -Syyu"
        ;;
        "ubuntu" | "debian")
            pkg_mngr_install="apt-get install -y"
            pkg_mngr_remove="apd-get remove -y"
            pkg_mngr_update="apt-get update && apt-get dist-upgrade -y"
        ;;
        "fedora")
            pkg_mngr_install="yum install -y"
            pkg_mngr_remove="yum remove -y"
            pkg_mngr_update="yum update && yum upgrade"
        ;;
    esac
    echo -e "Installing command:$pkg_mngr_install"
    echo -e "Removing command:$pkg_mngr_remove"
    echo -e "Update command:$pkg_mngr_update.""$RESETCOLOR"
}

## This function checks connection status
check_connection() {
    echo -e "$GREEN""[i] Checking network connection ...""$RESETCOLOR"
    ping -c3 archlinux.org > /dev/null 2>&1
    psts_one=$?
    ping -c3 google.com > /dev/null 2>&1
    psts_two=$?
    ping -c3 youtube.com > /dev/null 2>&1
    psts_three=$?
    if [ $psts_one -ne 0 ]; then
        is_online_try=$((is_online_try - 1))
    fi
    if [ $psts_two -ne 0 ]; then
        is_online_try=$((is_online_try - 1))
    fi
    if [ $psts_three -ne 0 ]; then
        is_online_try=$((is_online_try - 1))
    fi

    if [ $is_online_try -eq 0 ]; then
       echo -e "$RED[E] Connection ... failed.""$RESETCOLOR"
       exit
    fi

    echo -e "$GREEN""[i] Connection ... ok.$RESETCOLOR"
}

## This function execute the update
update() {

    echo -e "$GREEN""Updating repositories""$RESETCOLOR"
    eval "$pkg_mngr_update"
}

## This function echoes or run commands (dry run)

run() {
    if [ "$dry_run" = "$TRUE" ]; then
        echo -e "$1"
    else
        if [ "$verbose" = "$TRUE" ]; then
            eval "$1"
        else
            eval "$1 > /dev/null"
        fi
    fi
}

# This function enable services according to SERVICES array
set_services() {
    echo -e "$GREEN""Enabling $pkgs_list services""$RESETCOLOR"
    run "systemctl enable $pkgs_list"
}

# This function starts installation based on script.conf file.
start_proc() {

    stage_name=
    pkgs_list=
    # Read file line by line  ("#" identifies a comment)
    /usr/bin/grep -v '^#' $CFG_NAME | while read line
    do
        if [[ "$line" != "" ]]; then
          # split on ;  and get the name from -f1
          stage_name=$(echo $line | /usr/bin/cut -d ';' -f1)
          pkgs_list=$(echo $line | /usr/bin/cut -d ';' -f2)
          echo -e "$GREEN""Stage: $stage_name"
          if [ "$stage_name" = "SERVICE" ]; then
              set_services
          else
              if [ "$stage_name" = "REMOVE" ]; then
                echo -e "Removing: $pkgs_list""$RESETCOLOR"
                run "$pkg_mngr_remove $pkgs_list"
              else
                echo -e "Installing: $pkgs_list""$RESETCOLOR"
                run "$pkg_mngr_install $pkgs_list"
              fi
          fi
        fi
    done
}

## This function reads configuration files and copy data to destination
import_cfg() {

    clean_line=
    fname=
    fdestination=
    err=0
    echo -e "$GREEN""Configuring ...""$RESETCOLOR"
    # read file line by line omitting lines with comments (#)
    /usr/bin/grep -v '^#' $cf | while read line
    do
        # split on ;
        fname=$(echo $line | /usr/bin/cut -d ';' -f1)
        #echo "File name is $fname"
        fdestination=$(echo $line | /usr/bin/cut -d ';' -f2)
        #echo "File destination is $fdestination"
        # check each file exists in current folder
        #TODO: haven't we already checked this while processing args?
        if [ ! -f "$fname" ]; then
            echo -e "$BLUE""[W] File $fname not found ... skipping""$RESETCOLOR"
            err=$((err + 1))
        fi
        # check if destination exists
        if [ ! -d "$fdestination" ]; then
            echo -e "$BLUE""[W] Destination path $fdestination not found ... skipping""$RESETCOLOR"
            err=$((err + 1))
        fi
        if [ $err = 0 ]; then
            # execute the copy
            echo -e "$GREEN""copying $fname to $fdestination""$RESETCOLOR"
            if [ "$dry_run" = "$FALSE" ]; then
                /usr/bin/cp $fname $fdestination
            fi
        fi
        #reset error var
        err=0
    done
    echo -e "$BLUE""Configuring ...ok""$RESETCOLOR"

}

## @@@@@ MAIN ##

# Catch signals
trap "echo [W] Aborted by user.; exit" SIGHUP SIGINT SIGTERM

while getopts ':hdvVi:x' opt; do

    case "$opt" in
        "i")
            cf=$OPTARG
            if [ ! -f "$cf" ]; then
                echo -e "$RED""[E] Could not find $cf. Exiting.""$RESETCOLOR"
                exit
            fi
            is_config=$TRUE
        ;;
        "d")
            dry_run=$TRUE
        ;;
        "V")
            echo -e "$BLUE""$0 version: $VERSION""$RESETCOLOR"
            exit
        ;;
        "v")
            verbose=$TRUE
        ;;
        "h")
            usage
            exit
        ;;
        "?")
            usage
            exit
        ;;
    esac
done
shift $((OPTIND - 1))
# is superuser?
if (( $EUID != 0 )); then
    echo -e "$BLUE""Please run as privileged user.""$RESETCOLOR"
    exit
fi
# check right params
if [ $# -ne 1 ]; then
  echo -e "$RED""[E] param required.""$RESETCOLOR"
  exit
fi

if [ ! -f $1 ]; then
  echo -e "$RED""[E] $1 is not a valid file.""$RESETCOLOR"
  exit
fi
CFG_NAME=$1

# get package manager
get_pks_manager

# Check internet connection
check_connection

# update system
update

# Ready to go. Ask user confirmation
echo -e "$BLUE""This script will modify your system as you requested."
echo -ne "Shall we go? (yes/no): ""$RESETCOLOR"
read -t 10 ans

if [ "$ans" = "yes" ]; then

    # install software from categories and enable services
    start_proc
    # copy configuration files from custom location specified by user
    if [ $is_config = $TRUE ]; then
        import_cfg $cf
    fi
    echo -e "$0 execution completed. Thank you."
else
    echo -e "$BLUE""[i] Aborted ...""$RESETCOLOR"
fi
