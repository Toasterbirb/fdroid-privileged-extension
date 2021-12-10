#!/bin/bash

function _downloadError()
{
	echo "Could not download the OTA extension"
	echo "Please download it manually and proceed without using this script and follow the steps shown here: https://forum.f-droid.org/t/privileged-extension-ota-workaround-for-los-17-1/11058"
	exit 1
}

cacheDir=$HOME/.cache/fdroid_privileged_extension

[ -d $cacheDir ] && rm -r $cacheDir
mkdir -p $cacheDir

echo "Downloading the latest release..."
fdroidSite=$(curl -qs https://f-droid.org/en/packages/org.fdroid.fdroid.privileged.ota/)
zipFile=$(sed 's/^[[:space:]]*//g; /^$/d' <<< $fdroidSite | grep -A 31 "id=\"latest\"" | awk '/zip/' | sed 's/<a href="//g; s/">.*//g' | head -n1)

echo "ZIP File: $zipFile"
wget -q -O $cacheDir/ota.zip $zipFile && echo "Download successfull" || _downloadError

echo "Extracting files..."
unzip $cacheDir/ota.zip -d $cacheDir/

echo "Verifying that the required files were extracted successfully..."
function _missingFile()
{
	echo "$1 missing!"
}

[ -f "$cacheDir/F-DroidPrivilegedExtension.apk" ] || _missingFile "F-DroidPrivilegedExtension.apk"
[ -f "$cacheDir/permissions_org.fdroid.fdroid.privileged.xml" ] || _missingFile "permissions_org.fdroid.fdroid.privileged.xml"
[ -f "$cacheDir/F-Droid.apk" ] || _missingFile "F-Droid.apk"
[ -f "$cacheDir/80-fdroid.sh" ] || _missingFile "80-fdroid.sh"

echo "All required files where extracted successfully!"

echo "Starting installation of f-droid privileged installation"
echo "Please read the README.md carefully before proceeding!"
echo "I hope you know what you are doing..."
echo "Press ENTER to start (or Ctrl + C to abort the mission)"
read
adb root
adb remount
echo "Remounted. Press ENTER to start moving files"
read
adb push "$cacheDir/F-DroidPrivilegedExtension.apk" /system/priv-app/
adb push "$cacheDir/permissions_org.fdroid.fdroid.privileged.xml" /system/etc/permissions/
adb push "$cacheDir/F-Droid.apk" /system/app/
adb push "$cacheDir/80-fdroid.sh" /system/addon.d/
echo "Installation done rebooting"
adb reboot
