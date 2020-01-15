#!/bin/bash

#Le script est a executer à l'emplacement du .jar
#variable à adapter
minVer="1.14.4"
screenName="minecraftVanillaServer"
dir=$(pwd)
date=$(date +"%d-%m-%Y_%H_%M_%S")
#source:https://code-examples.net/en/q/bb009c
function find_screen {
    if screen -ls "$1" | grep -o "^\s*[0-9]*\.$1[ "$'\t'"](" --color=NEVER -m 1 | grep -oh "[0-9]*\.$1" --color=NEVER -m 1 -q >/dev/null; then
        screen -ls "$1" | grep -o "^\s*[0-9]*\.$1[ "$'\t'"](" --color=NEVER -m 1 | grep -oh "[0-9]*\.$1" --color=NEVER -m 1 2>/dev/null
        return 0
    else
        return 1
    fi
}


cd /tmp
rm latest 2>/dev/null
if ! wget https://papermc.io/api/v1/paper/${minVer}/latest &>>${dir}/logs/update-${date}.log
then
        echo "Error downloading JSON from ${minVer}"
        exit 1
fi

VERSIONSTRING=$(grep -Po '"build": *\K"[^"]*"' latest)
VERSION=$(perl -pe 's/\"//g' <<< "$VERSIONSTRING")
fileName=("paper-${VERSION}.jar")

cd $dir

if ! test -f $fileName
then
        oldFile=$(ls | grep "paper-[0-9]*.jar")

        if ! wget https://papermc.io/api/v1/paper/${minVer}/${VERSION}/download &>>${dir}/logs/update-${date}.log
        then
                echo "Error downloading build ${VERSION}"
                exit 2
        fi

        mv download $fileName

        #if server is on, stop
        if find_screen $screenName &>>${dir}/logs/update-${date}.log ; then
                screen -D -R $screenName -X stuff "say Update Server, Shutdown in 60 seconds $(printf '\r')"
                sleep 30s
		screen -D -R $screenName -X stuff "say Shutdown in 30 seconds $(printf '\r')"
                sleep 20s
		for (( i=10; i>=1; i-- ))do 
			screen -D -R $screenName -X stuff "say Shutdown in $i seconds $(printf '\r')" 
			sleep 1s; 
		done
		screen -D -R $screenName -X stuff "stop $(printf '\r')"
        fi

        rm -f $oldFile
fi

screen -d -S $screenName -m ./start.sh
