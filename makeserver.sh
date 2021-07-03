#!/bin/bash
# by using this script you accept the minecraft EULA (it will automatically create a eula.txt with eula=true)

# jq is unlikely to be installed by default
if ! command -v jq &> /dev/null; then
    echo "jq is not installed, installing..."
    sudo apt-get install -qq -y jq
fi

mkdir ~/mc
cd ~/mc

DOWNLOAD_MANIFEST=false
if [[ -e "version_manifest_v2.json" ]]; then 
    # only redownload file if it's been 30 minutes
    if find version_manifest_v2.json -mmin -30 &> /dev/null; then
        DOWNLOAD_MANIFEST=true
    fi
else
    DOWNLOAD_MANIFEST=true
fi

if $DOWNLOAD_MANIFEST; then
    echo "Downloading version manifest..."
    curl -O -J -s https://launchermeta.mojang.com/mc/game/version_manifest_v2.json
fi

VERSION=""

read -r -p "Get latest version? [y/n]: " LATEST_VER
if [[ "$LATEST_VER" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    VERSION="$(jq -r .latest.release version_manifest_v2.json)"
else
    read -r -p "Enter version: " VERSION
fi

echo "Downloading \"$VERSION\"..."
VERSION_MANIFEST_URL="$(jq -r ".versions[] | select(.id == \"$VERSION\").url" version_manifest_v2.json)"
if [[ VERSION_MANIFEST_URL == "" ]]; then
    echo "Error! Could not find server for version \"$VERSION\""
    exit 1
fi

mkdir $VERSION
cd $VERSION

SERVER_URL="$(curl $VERSION_MANIFEST_URL | jq -r .downloads.server.url)"
curl -O -J --progress-bar $SERVER_URL
echo "eula=true" > eula.txt

TOTAL_MEMORY_KB="$(grep MemTotal /proc/meminfo | awk '{print $2}')"
TOTAL_MEMORY="$(($TOTAL_MEMORY_KB/(1024*1024)))"
SERVER_MEMORY="$(($TOTAL_MEMORY - 1))" # leave 1GB for the system

echo "Starting $VERSION server (${SERVER_MEMORY}GB allocated)..."

# Aikar's jvm arguments
echo "#!/bin/bash" >> runserver.sh
echo java -Xmx${SERVER_MEMORY}G -Xms${SERVER_MEMORY}G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar nogui >> runserver.sh

java -Xmx${SERVER_MEMORY}G -Xms${SERVER_MEMORY}G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar nogui

