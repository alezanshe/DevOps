# Ejercicios Módulo 02 - Contenedores Docker

### Ejercicio 1

1. Para crear una red en la que los contenedores van a funcionar, hacemos uso del comando `docker network create ` mas el nombre de la red que queramos crear

```shell
$ docker network create lemoncode-challenge
```
2. Para que el backend se comunique con nuestra base de datos MongoDB, hay que modificar las siguientes lineas que tiene el archivo `config.ts` el cual está dentro de el directorio `src`

La modificaciones son las siguientes:

``` diff
if (process.env.NODE_ENV === 'development') {
    require('dotenv').config;
}

export default {
    database: {
-		url: process.env.DATABASE_URL || 'mongodb://localhost:27017',
+   	url: process.env.DATABASE_URL || 'mongodb://some-mongo:27017',
        name: process.env.DATABASE_NAME || 'TopicstoreDb'
    },
    app: {
-		host: process.env.HOST || 'localhost',
+       host: process.env.HOST || 'topics-api',
        port: +process.env.PORT || 5000
    }
}
```
La primera modificación apuntará al MongoDB el cual tiene el nombre `some-mongo` y conectará a través del puerto `27017`.

La segunda modificación declarará que el host es `topics-api` al cual luego nuestro frontend apuntará.

Estas modificaciones acompañado del flag `--hostname` cuando levantamos el contenedor nos permitira asignarle un nombre para que sea visible por las propias DNS de la red. Así los contenedores sabran quién es quién cuando se tenga que comunicar el backend con la base de datos y el frontend con el backend.

Por ejemplo:

```shell
$ --hostname topics-api
```

3. Antes que nada modificaremos la siguiente línea en el archivo `package.json

``` diff
{
  "name": "frontend",
  "version": "1.0.0",
  "description": "",
- "main": "index.js",
+ "main": "server.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "ejs": "^3.1.6",
    "express": "^4.17.1",
    "node-fetch": "^3.0.0"
  }
}
```
Editando esta línea conseguimos que el script "main" busque un `server.js` y no un un `index.js` el cual no existe.

El frontend buscará el contenedor llamado `topics-api` en el puerto `5000`.
Para ello, modificaremos la siguiente línea en el archivo `server.js`: 

``` diff
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const express = require('express'),
    app = express();

- const LOCAL = 'http://localhost:5000/api/topics';
+ const LOCAL = 'http://topics-api:5000/api/topics';

app.set('view engine', 'ejs');

app.get('/', async (req, res) => {

    //Recuperar topics de la API
    const response = await fetch(process.env.API_URI || LOCAL);
    const topics = await response.json();

    res.render('index', { topics });

});

- app.listen(3000, () => {
-   console.log(`Server running on port 3000 with ${process.env.API_URI || LOCAL}`);
+ app.listen(8080, () => {
+   console.log(`Server running on port 8080 with ${process.env.API_URI || LOCAL}`);
});
```

4. La segunda modificación en este archivo declara en que puerto escuchará. Por defecto esta en el puerto `3000`. Podemos modificarlo al `8080` como pide el ejercicio o también podemos mapearlo con el flag `-p`

```shell
$ -p 8080:3000
```

5. El MongoDB debe almacenar la información que va generando en un volumen, mapeado a la ruta /data/db.

Para ello haremos uso del flag `-v` que mapea una ruta local en el directorio correspondiente del contenedor MongoDB el cual es `/data/db`

Por ejemplo:

```shell
$ docker run -d -p 27017:27017 -v data:/data/db mongo
```
Esto usará la carpeta data que tenemos en la ruta actual y la mapeará con `/data/db` para que cuando se pare o borremos el contenedor los datos no se pierdan. Si volviesemos a levantar otro contenedor y le mapeáramos este mismo volumen, los datos seguirían estando ahí

6. Para inicializar la base de datos de MongoDB que contendrá nuestros datos entraremos en nuestro contenedor MongoDB usando la terminal:

```shell
$ docker exec -it some-mongo bash
```

Una vez dentro usaremos el comando `mongosh` para operar con la shell de MongoDB e introduciremos los siguientes comandos para:

```shell
$ mongosh
```

Crear la base de datos `TopicstoreDb`

```shell
test> use TopicstoreDb
```
Crear la colección `Topics` e introducir datos

```shell
db.Topics.insert( { Name: "Docker" } )
```

```shell
db.Topics.insert( { Name: "Kubernetes" } )
```

```shell
db.Topics.insert( { Name: "Jenkins" } )
```

```shell
db.Topics.insert( { Name: "CI/CD" } )
```

Una vez hayamos introducido nuestros registros en la base de datos, si usamos `curl` para ver el contenido de http://localhost:5000/api/topics veremos el contenido de la base de datos

```shell
$ curl http://localhost:5000/api/topics
```

Resultado:

```shell
[{"Name":"Docker","id":"6385140b706eab71d6bc59d2"},{"Name":"Kubernetes","id":"63851412706eab71d6bc59d3"},{"Name":"Jenkins","id":"6385141a706eab71d6bc59d4"},{"Name":"CI/CD","id":"63851420706eab71d6bc59d5"}]
```

* Nota: Nos encontramos con que una vez introducidos los datos en la base de datos, no se printaban bien los registros por lo que editando el archivo `index.ejs` corrige este error

```diff
<!doctype html>
<html lang="en">

<head>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.0/dist/css/bootstrap.min.css" rel="stylesheet"
        integrity="sha384-KyZXEAg3QhqLMpG8r+8fhAXLRk2vvoC2f3B09zVXn8CA5QIVfZOJ3BCsw2P0p/We" crossorigin="anonymous">

    <title>Lemoncode Challenge</title>
</head>

<body>
    <div class="container">
        <div class="row">
            <h1>Topics</h1>
        </div>
        <div class="row">

            <ul class="list-group">
                <% topics.forEach(function(topic){ %>
                    <li class="list-group-item">
-                       <%- topic.topicName %>
+                       <%- topic.Name %>
                    </li>
                    <%});%>
            </ul>
        </div>
    </div>
    <!-- Option 1: Bootstrap Bundle with Popper -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.0/dist/js/bootstrap.bundle.min.js"
        integrity="sha384-U1DAWAznBHeqEIlVSCgzq+c9gqGAJn5c/t99JyeKa9xxaYpSvHU5awsuZVVFIhvj"
        crossorigin="anonymous"></script>
</body>

</html>
```

Actualizacion:

Para crear las imagenes `Dockerfile` que después `Docker-Compose` usará para levantarlo todo usaremos el comando:

```shell
docker build . -t nombreimagen
```

(El . significa el directorio actual. Si  estuvíesemos en otra ruta bastaría con escribir la ruta absoluta hasta el Dockerfile)

### Ejercicio 2

Crearemos un `docker-compose.yml` que contendrá toda la configuración antes mencionada y almacenada en los `Dockerfile` tanto del backend como del frontend.

```shell
version: '3.9'

services:

  mongo:
    image: mongo
    restart: always
    container_name: some-mongo
    hostname: some-mongo
    volumes:
      - ./data:/data/db
      - ./data/log:/var/mongodb
    ports:
      - "27017:27017"
    networks:
      - lemoncode-challenge

  backend:
    build: ./backend/
    restart: always
    container_name: topics-api
    hostname: topics-api
    ports:
      - "5000:5000"
    networks:
      - lemoncode-challenge

  frontend:
    build: ./frontend/
    restart: always
    container_name: frontend
    hostname: frontend
    ports:
      - "8080:8080"
    networks:
      - lemoncode-challenge

networks:
  lemoncode-challenge:
```

Para iniciar, parar o eliminar toda la aplicación, bastaría con situarnos en la ruta donde tenemos nuestro `docker-compose.yml` y escribir los siguientes comandos:

Para iniciar:

```shell
$ docker-compose up -d
```

Para parar:

```shell
$ docker-compose stop
```

Para eliminar:

```shell
$ docker-compose down
```

Para eliminar (incluido volúmenes):

```shell
$ docker-compose down -v
```