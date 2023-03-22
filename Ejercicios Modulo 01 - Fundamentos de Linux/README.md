# Ejercicios Módulo 01 - Fundamentos de Linux

## Ejercicios CLI

### Ejercicio 1: Crea mediante comandos de bash la siguiente jerarquía de ficheros y directorios 

Para crear directorios hacemos uso de `mkdir`

```shell
$ mkdir directorio
```

Asi que para crear el directorio de `foo` y los directorios hijos `dummy` y `empty` podemos hacer uso de:
```shell
$ mkdir foo
$ cd foo
$ mkdir dummy
$ mkdir empty
```

O bien crear directamente todo usando el flag `-p`
``` shell
$ mkdir -p foo/dummy foo/empty 
```

Nos dirigimos al directorio `dummy` y haciendo uso de nuestro editor de texto favorito como `vim` o `nano` creamos los archivos de texto `file1.txt` y `file2.txt` e introducimos *Me encanta la bash!!*

``` shell
$ touch file1.txt 
```

``` shell
$ touch file2.txt 
```

Podemos hacer uso de `>` para introducir un `echo` dentro de un archivo de texto

``` shell
$ echo "Me encanta la bash" > file1.txt 
```
La estructura de directorios debería de quedar asi:
```shell
foo/
├─ dummy/
│  ├─ file1.txt
│  ├─ file2.txt
├─ empty/
```
Para ver de este modo la estructura de cualquier directorio podemos descargar el paquete `tree`

``` shell
$ sudo apt install tree 
```

### Ejercicio 2: Mediante comandos de bash, vuelca el contenido de file1.txt a file2.txt y mueve file2.txt a la carpeta empty

Para mover el contenido de `file1.txt` a `file2.txt` podríamos usar el comando

``` shell
$ cp file1.txt file2.txt
```

Pero si quisieramos obtener el mismo resultado sin usar el comando `cp` podemos hacer

``` shell
$ cat file1.txt > file2.txt
```

Para mover `file2.txt` usamos el comando `mv`

``` shell
$ mv file2.txt ../empty
```
Entonces la estructura del directorio quedaria asi

``` shell
$ foo/
├─ dummy/
│  ├─ file1.txt
├─ empty/
   ├─ file2.txt
```

### Ejercicio 3: Crear un script de bash que agrupe los pasos de los ejercicios anteriores y además permita establecer el texto de file1.txt alimentándose como parámetro al invocarloMediante comandos de bash, vuelca el contenido de file1.txt a file2.txt y mueve file2.txt a la carpeta empty

Hemos creado el archivo `Ejercicio3.sh` el cual crea una serie de directorios, crea dos archivos de texto, los introduce en los dos directorios y pasa en uno de ellos un argumento como texto. En el caso de que no se indicara ningun argumento, el texto mostrará una frase

Finalmente, mostrará el arbol de directorios con el comando `tree` el cual es instalado al principio del script

``` shell
$ nano Ejercicio3.sh
```
Y le hemos dado permisos de ejecucion con `chmod`

``` shell
$ chmod +x Ejercicio3.sh
```

A continuación mostramos el contenido de `Ejercicio3.sh`:

``` shell
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
```

Al pasar un argumento, el script lo introduce en el archivo de texto y lo muestra por pantalla con un `cat`

```shell
$ /Ejercicio3.sh 'Hola que tal'
```

```
El argumento Hola que tal se ha introducido en file1.txt y se muestra abajo:
Hola que tal

Mostrando Tree del directorio:

/home/devops/Downloads/foo
├── dummy
│   └── file1.txt
└── empty
    └── file2.txt
```

### Ejercicio 4: Crea un script de bash que descargue el contenido de una página web a un fichero y busque en dicho fichero una palabra dada como parámetro al invocar el script

Hemos usado la típica web de ejemplos de `Lorem Ipsum`

```
https://getlorem.com/es
```

Para descargar el contenido de una pagina web hacemos uso del comando `curl`

```shell
$ curl URL
```

Y para descargar el contenido a un archivo vamos a usar el flag `-o`

```shell
$ curl -o archivo URL
```

En nuestro caso
```shell
$ curl -o curl.txt https://getlorem.com/es
```
Si hicieramos

```shell
$ cat curl.txt
```

Nos mostraría el contenido descargado de la web

Para buscar palabras dentro de un archivo grepeado usaremos el comando `grep` con el flag `-o` para que muestre solo las que coincidan

```shell
$ grep -o "ipsum" curl.txt
```

Para este ejercicio se ha creado un script con el nombre `Ejercicio4.sh` que hace curl a una web, la descarga a un archivo de texto llamado `curl.txt` y busca en el interior del archivo el primer parámetro introducido.
Si esta palabra existiese en el archivo `curl.txt` devolverá por pantalla cuantas veces se repite y en que línea apareció por primera vez.

En caso contrario, mostrará que no existe

```shell
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
```

A modo de ejemplo vamos a correr el script pasandole el argumento *ipsum*

```shell
$ ./Ejercicio4.sh ipsum
```

Resultado:

```
La palabra ipsum aparece 6 veces y aparece por primera vez en la linea 26
```

```shell
$ ./Ejercicio4.sh patata
```

Resultado:

```
No se ha encontrado la palabra patata en el archivo curl.txt
```