#!/bin/bash

#Fonction
showHelp() {
cat <<EOF
./script.sh [OPTIONS...]
Help:
   -h, --help		display this help and exit.
   -i, --info		display info and exit.
Options:
   --version=STRING	indique la version de minecraft à lancer ["1.16.1"]
   --name=STRING   	donne un nom au terminal screen ["minecraftServer"]
   --ram=STRING    	indique la ram max que java utilisera ["1G"]
EOF
exit 0
}

showInfo(){
cat <<EOF
Lance/met à jour un serveur paper sur le dernier build
Script version: $version

EOF
exit 0;
}

app_is_installed(){ 
	if dpkg -s "$1" &>/dev/null ; then 
		return 0
	else 
		echo "$1 n\'est pas installé"
		exit 1
	fi
}

#source:https://code-examples.net/en/q/bb009c
#test si il existe déjà un screen ouvert
function find_screen {
    if screen -ls "$1" | grep -o "^\s*[0-9]*\.$1[ "$'\t'"](" --color=NEVER -m 1 | grep -oh "[0-9]*\.$1" --color=NEVER -m 1 -q >/dev/null; then
        screen -ls "$1" | grep -o "^\s*[0-9]*\.$1[ "$'\t'"](" --color=NEVER -m 1 | grep -oh "[0-9]*\.$1" --color=NEVER -m 1 2>/dev/null
        return 0
    else
        return 1
    fi
}
################################################################################
#Variable
version="1.16.1"
screenName="minecraftServer"
dir=$(dirname "$0")
date=$(date +"%d-%m-%Y_%H_%M_%S")
javaXm="1G"
version=1.0

################################################################################
#arg
for opt in $@; do
   optX=$opt
   optval="${opt#*=}"
   case "$opt" in
      --help|-h) showHelp
      ;;
      --info|-i) showInfo
      ;;
	  --name=*) screenName=$optval
	  ;;
	  --ram=*) javaXm=$optval
	  ;;
	  --version=*) version=$optval
	  ;;
      *)
         echo "Unknown option $1"
		 exit 1
         ;;
  esac
done

################################################################################
#Vérification des programmes installé
app_is_installed screen
app_is_installed wget
if ! java -version &>/dev/null; then echo "java n\'est pas installé"; fi

################################################################################
#Récupère le numéro de la dernière version du build
if ! wget -nv https://papermc.io/api/v1/paper/${version}/latest
then
        echo "Error downloading JSON from ${version}"
        exit 1
fi
BUILDSTRING=$(grep -Po '"build": *\K"[^"]*"' latest)
BUILD=$(perl -pe 's/\"//g' <<< "$BUILDSTRING")
fileName=("paper-${version}-${BUILD}.jar")
rm latest 2>/dev/null

cd $dir

#Si le fichier n'existe pas
if ! test -f $fileName
then

		# Récupère le nom des anciens fichier
        oldFile=$(ls | grep "paper-$version-[0-9]*.jar")

		# Télécharge le build récent
        if ! wget -nv https://papermc.io/api/v1/paper/${version}/${BUILD}/download
        then
                echo "Error downloading build ${BUILD}"
                exit 2
        fi

        mv download $fileName

        #if server is on, stop
        if find_screen $screenName ; then
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

		# Supprime les anciennes versions seulement après que le serveur soit stop
        rm -f $oldFile
fi

screen -d -S $screenName -m java -Xms$javaXm -Xmx$javaXm -jar $fileName
