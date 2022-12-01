#!/bin/bash

echo "Instalando tree..."
echo
sudo apt install tree -y

echo

mkdir -p foo/dummy foo/empty

cd foo/dummy/ && echo 'Me encanta la bash!!' > file1.txt && touch file2.txt

cat file1.txt > file2.txt && mv file2.txt ../empty

if [[ $1 == "" ]]; then
	echo "No has introducido ningun argumento, el contenido de file1.txt es:"
	echo
	echo "Me encanta la bash!!" > file1.txt
        cat file1.txt
	echo
else
        echo $1 > file1.txt && echo "El argumento $1 se ha introducido en file1.txt y se muestra abajo:"
        cat file1.txt
	echo
fi

echo "Mostrando Tree del directorio:"

echo

cd

tree /home/$USER/Downloads/foo
