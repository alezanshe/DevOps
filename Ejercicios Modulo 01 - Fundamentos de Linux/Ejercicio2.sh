#!/bin/bash

touch curl.txt

count=$(curl -s -o curl.txt https://getlorem.com/es | grep -o $1 curl.txt | wc -l)
word=$(curl -s -o curl.txt https://getlorem.com/es | grep -o $1 curl.txt)
line=$(grep -n $1 curl.txt | head -n 1 | cut -d: -f1)

if [[ $count == 0 ]]; then
	echo "No se ha encontrado la palabra $1 en el archivo curl.txt"
else
	echo "La palabra $1 aparece $count veces y aparece por primera vez en la linea $line"
fi
