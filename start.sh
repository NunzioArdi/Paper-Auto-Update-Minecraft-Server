#!/bin/bash
usage="Usage $0 <fileServer.jar>"

paperFile=$(find . -name 'paper-[0-9]*.jar' | sort -nr | head -1)

java -Xms128M -Xmx1536M -jar $paperFile

