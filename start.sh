#!/bin/bash

# .-------------------------------.
# | Minecraft Server Auto Updater |
# '-------------------------------'
#           Version 1.0

# This start script automatically downloads the latest available version of Purpur and runs it
# Dependencies:
# - coreutils (https://www.gnu.org/software/coreutils/) for verifying downloads
# - java (https://adoptium.net/) for running the server
# - jq (https://jqlang.github.io/jq/) for processing information used to download the server
# - Linux or macOS for running this script, Windows version coming when I feel like it

# ---- WARNING ----
# This server is not sandboxed by default, meaning you may be vulnerable to malware
# Only download plugins/mods from trusted developers.
# NetworkInterceptor (https://github.com/SlimeDog/NetworkInterceptor/wiki) is highly recommended.
# NEVER run as root or sudo, you should create a separate account on your computer to run Minecraft servers!!!!

# If you are port forwarding your server, enable Minecraft's whitelist if you don't want random people joining and griefing or harassing you.
# There are bots that will scan the internet for your server and alert griefers.
# If you don't know how to do this, go to https://shockbyte.com/billing/knowledgebase/91/How-to-Setup-and-Manage-Whitelisting.html
# For more information on these bots, watch https://youtu.be/hoS0PM20KJk
# A free plugin you can use to backup your server is CoreProtect (https://hangar.papermc.io/CORE/CoreProtect)

# For other people to join your server, you'll need to either port forward or run a program like playit.gg
# Port forwarding instructions can be found at https://minecraft.fandom.com/wiki/Tutorials/Setting_up_a_server#Firewalling,_NATs_and_external_IP_addresses
# If you can't or don't want to port forward, you can use https://playit.gg/ (not sponsored or affiliated)

# Planned features (feel free to suggest more!):
# - Support for Forge, Fabric, and Quilt
# - Scheduled automatic restarts

# What is not planned (may change in the future):
# - Web console (out of scope, use RCON or a plugin like DiscordSRV)
# - Automatic updating of plugins/mods (out of scope)
# - Automatic modpack updates (out of scope, use https://docker-minecraft-server.readthedocs.io/en/latest/mods-and-plugins/)

# The server type to use (default: purpur)
# Supported server types:
# - folia (https://papermc.io/software/folia)
# - paper (https://papermc.io/software/paper)
# - purpur (https://purpurmc.org)
SERVER_TYPE=purpur
# If you are having problems with your server crashing after the console says "Starting background profiler", try disabling Spark. This only applies when using Purpur. (default: false)
DISABLE_SPARK=false
# Whether or not to use Aikar's flags. It is not recommended to turn this off unless you know what you are doing. For more information, go to https://docs.papermc.io/paper/aikars-flags (default: true)
USE_AIKARS_FLAGS=true
# The amount of deditated wam to allocate in gigabytes. It is recommended to use up to half of what is available in your computer. (default: 4)
MEMORY=4
# The version of Minecraft to run (default: latest)
MINECRAFT_VERSION=latest

# Don't touch below unless you know what you are doing!

function verifyMD5() {
  echo "$1 server.jar" | md5sum --status --check -
  echo $?
}

function verifySHA256() {
  echo "$1 server.jar" | sha256sum --status --check -
  echo $?
}

while true; do

  # fetches information used to download the server jar
  # currently only supports direct downloads of server jars
  # support for installers, such as for most mod loaders, should be added at some point
  if [ "$SERVER_TYPE" = "purpur" ]; then
    SELECTED_MINECRAFT_VERSION=$([ "$MINECRAFT_VERSION" = "latest" ] && echo "$(curl -sS 'https://api.purpurmc.org/v2/purpur' | jq -r '.versions[]' | sort -V | tail -1)" || echo "$MINECRAFT_VERSION" ) # the version of minecraft
    LATEST_BUILD=$(curl -sS "https://api.purpurmc.org/v2/purpur/$SELECTED_MINECRAFT_VERSION" | jq -r '.builds.latest') # the build number
    HASH=$(curl -sS "https://api.purpurmc.org/v2/purpur/$SELECTED_MINECRAFT_VERSION/$LATEST_BUILD" | jq -r '.md5') # the hash used to verify the download
    HASH_TYPE=md5 # md5 or sha256
    DOWNLOAD_URL="https://api.purpurmc.org/v2/purpur/$SELECTED_MINECRAFT_VERSION/$LATEST_BUILD/download" # download url, should be a direct download
    SERVER_TYPE_NAME=Purpur # The formatted name
    SELECTED_USE_AIKARS_FLAGS=$USE_AIKARS_FLAGS # This would be set to false if the server type doesn't support Aikar's flags, which may be the case for server types added in later versions
  elif [ "$SERVER_TYPE" = "paper" ]; then
    SELECTED_MINECRAFT_VERSION=$([ "$MINECRAFT_VERSION" = "latest" ] && echo "$(curl -sS 'https://api.papermc.io/v2/projects/paper' | jq -r '.versions[]' | sort -V | tail -1)" || echo "$MINECRAFT_VERSION" )
    LATEST_BUILD=$(curl -sS "https://api.papermc.io/v2/projects/paper/versions/$SELECTED_MINECRAFT_VERSION" | jq -r '.builds[]' | sort -V | tail -1)
    HASH=$(curl -sS "https://api.papermc.io/v2/projects/paper/versions/$SELECTED_MINECRAFT_VERSION/builds/$LATEST_BUILD" | jq -r '.downloads.application.sha256')
    HASH_TYPE=sha256
    DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/$SELECTED_MINECRAFT_VERSION/builds/$LATEST_BUILD/downloads/$(curl -sS "https://api.papermc.io/v2/projects/paper/versions/$SELECTED_MINECRAFT_VERSION/builds/$LATEST_BUILD" | jq -r '.downloads.application.name')"
    SERVER_TYPE_NAME=Paper
    SELECTED_USE_AIKARS_FLAGS=$USE_AIKARS_FLAGS
  elif [ "$SERVER_TYPE" = "folia" ]; then
    SELECTED_MINECRAFT_VERSION=$([ "$MINECRAFT_VERSION" = "latest" ] && echo "$(curl -sS 'https://api.papermc.io/v2/projects/folia' | jq -r '.versions[]' | sort -V | tail -1)" || echo "$MINECRAFT_VERSION" )
    LATEST_BUILD=$(curl -sS "https://api.papermc.io/v2/projects/folia/versions/$SELECTED_MINECRAFT_VERSION" | jq -r '.builds[]' | sort -V | tail -1)
    HASH=$(curl -sS "https://api.papermc.io/v2/projects/folia/versions/$SELECTED_MINECRAFT_VERSION/builds/$LATEST_BUILD" | jq -r '.downloads.application.sha256')
    HASH_TYPE=sha256
    DOWNLOAD_URL="https://api.papermc.io/v2/projects/folia/versions/$SELECTED_MINECRAFT_VERSION/builds/$LATEST_BUILD/downloads/$(curl -sS "https://api.papermc.io/v2/projects/folia/versions/$SELECTED_MINECRAFT_VERSION/builds/$LATEST_BUILD" | jq -r '.downloads.application.name')"
    SERVER_TYPE_NAME=Paper
    SELECTED_USE_AIKARS_FLAGS=$USE_AIKARS_FLAGS
  fi

  # downloader
  # this should probably be cleaned up eventually and move to functions
  if [ -e server.jar ]; then
    if [ "$HASH_TYPE" = "md5" ]; then
      if [ "$(verifyMD5 "$HASH")" != 0 ]; then
        echo "Updating server to $SERVER_TYPE_NAME build $LATEST_BUILD for $SELECTED_MINECRAFT_VERSION..."
        rm -f server.jar
        curl -L -# -o server.jar "$DOWNLOAD_URL"
        echo Verifying hash...
        if [ "$(verifyMD5 "$HASH")" != 0 ]; then
          echo Downloaded JAR does not match hash, try restarting.
          exit 1
        else
          echo Verification successful!
        fi
      fi
    elif [ "$HASH_TYPE" = "sha256" ]; then
      if [ "$(verifySHA256 "$HASH")" != 0 ]; then
        echo "Updating server to $SERVER_TYPE_NAME build $LATEST_BUILD for $SELECTED_MINECRAFT_VERSION..."
        rm -f server.jar
        curl -L -# -o server.jar "$DOWNLOAD_URL"
        echo Verifying hash...
        if [ "$(verifySHA256 "$HASH")" != 0 ]; then
          echo Downloaded JAR does not match hash, try restarting.
          exit 1
        else
          echo Verification successful!
        fi
      fi
    fi
  else
    echo "Updating server to $SERVER_TYPE_NAME build $LATEST_BUILD for $SELECTED_MINECRAFT_VERSION..."
    curl -L -# -o server.jar "$DOWNLOAD_URL"
    echo Verifying hash...
    if [ "$HASH_TYPE" = "md5" ]; then
      if [ "$(verifyMD5 "$HASH")" != 0 ]; then
        echo Downloaded JAR does not match hash, try restarting.
        exit 1
      else
        echo Verification successful!
      fi
    elif [ "$HASH_TYPE" = "sha256" ]; then
      if [ "$(verifySHA256 "$HASH")" != 0 ]; then
        echo Downloaded JAR does not match hash, try restarting.
        exit 1
      else
        echo Verification successful!
      fi
    fi
  fi

  echo "eula=true" > eula.txt
  echo Starting server...

  # Convert gigabytes to megabytes
  MEMORY_MB=$(($MEMORY * 1024))M

  # Run the server using the correct flags
  if $SELECTED_USE_AIKARS_FLAGS; then
    if [ $MEMORY -ge 12 ]; then
      if [ "$SERVER_TYPE" = "purpur" ]; then
        if $DISABLE_SPARK; then
          java -Xms$MEMORY_MB -Xmx$MEMORY_MB -DPurpur.IReallyDontWantSpark=true --add-modules=jdk.incubator.vector -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar --nogui
        else
          java -Xms$MEMORY_MB -Xmx$MEMORY_MB --add-modules=jdk.incubator.vector -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar --nogui
        fi
      else
        java -Xms$MEMORY_MB -Xmx$MEMORY_MB -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar --nogui
      fi
    else
      if [ "$SERVER_TYPE" = "purpur" ]; then
        if $DISABLE_SPARK; then
          java -Xms$MEMORY_MB -Xmx$MEMORY_MB -DPurpur.IReallyDontWantSpark=true --add-modules=jdk.incubator.vector -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar --nogui
        else
          java -Xms$MEMORY_MB -Xmx$MEMORY_MB --add-modules=jdk.incubator.vector -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar --nogui
        fi
      else
        java -Xms$MEMORY_MB -Xmx$MEMORY_MB -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar --nogui
      fi
    fi
  else
    java -Xms$MEMORY_MB -Xmx$MEMORY_MB -jar server.jar --nogui
  fi

  echo Server restarting in 3 seconds...
  echo Press CTRL + C to stop.
  sleep 3
done
