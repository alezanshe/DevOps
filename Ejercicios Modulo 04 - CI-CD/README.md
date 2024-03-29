## Jenkins

### 1. CI/CD de una Java + Gradle

Este pipeline es sencillo ya que básicamente lo que tenemos que hacer es, clonar el repositorio, compilar con Gradle y correr los tests. Gradle viene dentro del directorio así que este pipeline lo podemos correr en Jenkins creando un nuevo proyecto de tipo pipeline y pegandolo directamente en el editor

```
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                sh '''
                git clone https://github.com/alezanshe/jenkins.git
                cd jenkins1/
                '''
            }
        }
        stage('Compile') {
            steps {
                sh './gradlew compileJava'
            }
        }
        stage('Unit Tests') {
            steps {
                sh './gradlew test'
            }
        }
    }
}
```

### 2. Modificar la pipeline para que utilice la imagen Docker de Gradle como build runner

Este pipeline es parecido al anterior solo que usa la imagen de Docker `gradle:6.6.1-jre14-openj9`. Hará lo mismo, clonará el repositorio, compilará con Gradle y correrá los tests con la imagen proporcionada. Para que use Docker, tenemos que haber instalado previamente los plugins de Docker para Jenkins. Para usarlo en local podemos hacer uso de `Dind` o `Docker in Docker`

```
pipeline {
    agent {
        docker {
            image 'gradle:6.6.1-jre14-openj9'
        }
    }
    stages {
        stage('Checkout') {
            steps {
                sh 'git clone https://github.com/alezanshe/jenkins.git'
            }
        }
        stage('Compile') {
            steps {
                sh '''
                cd jenkins/calculator
                ./gradlew compileJava
                '''
            }
        }
        stage('Unit Tests') {
            steps {
                sh '''
                cd jenkins/calculator
                ./gradlew test
                '''
            }
        }
    }
}
```

## Gitlab

### 1. CI/CD de una aplicación spring

Este pipeline en Gitlab se compone de 4 fases:

```
  - maven:build
  - maven:test
  - docker:build
  - deploy
```

Para empezar crearemos un repositorio y subiremos el código proporcionado

El pipeline iniciará la build con `Maven`, guardará los artefactos generados, luego correrá los tests a esos artefactos para ver que todo esta correcto. 

Tras los tests, `Docker` hará login en los repositorios oficiales, hará la build y hará push de la imagen a nuestro repositorio de `DockerHub`

Usando las variables de entorno de Gitlab nos hará que el pipeline esté mas limpio y sin hardcodear nada

El deploy con Docker simplemente hará `docker run` con el nombre que le hayamos dado a nuestra imagen y la tag que se le haya dado y arrancará el contenedor en el puerto 8080 con un mensaje diciendo

```
"hostname":"f4f0e622a178","ip":"172.17.0.2","message":"Hello World!"
```

```
stages:
  - maven:build
  - maven:test
  - docker:build
  - deploy

maven:build:
  image: maven:3.6.3-jdk-8-slim
  stage: maven:build
  script:
    - mvn clean package
  artifacts:
    paths:
      - "target/*.jar"

maven:test:
  image: maven:3.6.3-jdk-8-slim
  stage: maven:test
  dependencies:
    - maven:build
  script:
    - mvn verify
  artifacts:
    paths:
      - "target/"

build:
  stage: docker:build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY/$CI_PROJECT_PATH
  script:
    - docker build -t $CI_REGISTRY/$CI_PROJECT_PATH:$CI_COMMIT_SHA . 
    - docker push $CI_REGISTRY/$CI_PROJECT_PATH:$CI_COMMIT_SHA
    
deploy:
   stage: deploy
   before_script:
     - docker login -u $CI_REGISTRY_USER -p $CI_JOB_TOKEN $CI_REGISTRY/$CI_PROJECT_PATH
   script:
     - docker run --name "springapp" -d -p 8080:8080 $CI_REGISTRY/$CI_PROJECT_PATH:$CI_COMMIT_SHA
```

## 2. Crear un usuario nuevo y probar que no puede acceder al proyecto anteriormente creado

## Guest
El usuario `Guest` puede:

- Ver el código fuente y los archivos del proyecto.
- Ver las solicitudes de extracción y los problemas en el proyecto.
- Ver los comentarios en las solicitudes de extracción y los problemas.
- Ver el registro de actividad del proyecto.
- Ver los archivos de registro de la construcción de CI/CD, pero no pueden modificar la configuración de CI/CD.
- Crear solicitudes de extracción en un fork del proyecto, pero no pueden hacerlo directamente en el proyecto original.
- Crear problemas en el proyecto.

## Reporter
El usuario `Reporter` puede:

- Ver el código fuente y los archivos del proyecto.
- Ver las solicitudes de extracción y los problemas en el proyecto.
- Ver los comentarios en las solicitudes de extracción y los problemas.
- Ver el registro de actividad del proyecto.
- Ver los archivos de registro de la construcción de CI/CD, pero no pueden modificar la configuración de CI/CD.
- Crear solicitudes de extracción en el proyecto.
- Crear problemas en el proyecto.
- Comentar en solicitudes de extracción y problemas.
- Ver los detalles de la configuración del proyecto y las ramas protegidas.
- Ver el contenido de la Wiki del proyecto.
- Ver y descargar los artefactos de construcción de CI/CD.

## Developer
El usuario `Developer` puede:

- Ver y modificar el código fuente y los archivos del proyecto.
- Crear y modificar las solicitudes de extracción en el proyecto.
- Crear y cerrar problemas en el proyecto.
- Comentar en solicitudes de extracción y problemas.
- Ver el registro de actividad del proyecto.
- Ver y descargar los artefactos de construcción de CI/CD.
- Configurar y ejecutar la construcción de CI/CD para el proyecto.
- Acceder a los entornos de producción y de prueba.
- Ver y modificar la configuración del proyecto, incluyendo la configuración de CI/CD y las ramas protegidas.

## Mantainer
El usuario `Mantainer` puede:

- Ver y modificar el código fuente y los archivos del proyecto.
- Crear y modificar las solicitudes de extracción en el proyecto.
- Crear y cerrar problemas en el proyecto.
- Comentar en solicitudes de extracción y problemas.
- Ver y descargar los artefactos de construcción de CI/CD.
- Configurar y ejecutar la construcción de CI/CD para el proyecto.
- Acceder a los entornos de producción y de prueba.
- Ver y modificar la configuración del proyecto, incluyendo la configuración de CI/CD y las ramas protegidas.
- Aprobar solicitudes de extracción y fusionarlas con el repositorio.
- Crear, modificar y eliminar ramas protegidas.
- Invitar, eliminar y modificar los roles de los miembros del proyecto.
- Crear, modificar y eliminar etiquetas y lanzamientos.

### 3. Crear un nuevo repositorio, que contenga una pipeline, que clone otro proyecto, springapp anteriormente creado. Realizarlo de las siguientes maneras:

__¿Qué ocurre si el repo que estoy clonando no estoy cómo miembro?__

No se puede clonar porque es privado por defecto

## GitHub Actions

### 1. Crea un workflow CI para el proyecto de frontend

Este pipeline de Github Actions hará build de nuestra app en NodeJS usando el actions `setup-node` y luego correrá los tests. Este pipeline solo se activará cuando se realice un pull request

```
name: CI

on: pull_request
    
jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: 16
          cache: 'npm'
          cache-dependency-path: hangman-front/package-lock.json
      - name: Install Dependencies
        working-directory: ./hangman-front
        run: npm ci
      - name: Build
        working-directory: ./hangman-front
        run: npm run build
      - name: Run Tests
        working-directory: ./hangman-front
        run: npm run test
```
### 2. Crea un workflow CD para el proyecto de frontend

Este pipeline de Github Actions hará exactamente lo mismo que el pipeline anterior solo que se disparará manualmente (usando workflow_dispatch) y hará una build de Docker de un Dockerfile y hará push a los repos de GitHub (ghcr.io). En este paso del pipeline yo lo he hecho manualmente haciendo Docker Login con un Token proporcionado por GitHub que permite interactuar con Packages pero se podría haber realizado todo con el action `build-push-action`

```
name: CI

on:
  workflow_dispatch:

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: 16
          cache: 'npm'
          cache-dependency-path: hangman-front/package-lock.json
      - name: Install Dependencies
        working-directory: ./hangman-front
        run: npm ci
      - name: Build
        working-directory: ./hangman-front
        run: npm run build
      - name: Run Tests
        working-directory: ./hangman-front
        run: npm run test
      - name: Upload Artifact
        uses: actions/upload-artifact@v2
        with:
          name: build-code
          path: hangman-front/dist/

  docker-login-build-push:
    runs-on: ubuntu-latest
    needs: build-and-test
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: 16
          cache: 'npm'
          cache-dependency-path: hangman-front/package-lock.json
      - name: Download Artifact
        uses: actions/download-artifact@v2
        with:
          name: build-code
          path: hangman-front/dist/
      - name: Docker Login
        run: echo ${{ secrets.TOKEN }} | docker login ghcr.io -u echo ${{ secrets.GITHUB_ACTOR }} --password-stdin
      - name: Docker Build
        working-directory: ./hangman-front
        run: docker build -t ghcr.io/alezanshe/hangman-front/hangman-front:latest .
      - name: Docker push
        run: docker push ghcr.io/alezanshe/hangman-front/hangman-front:latest
```

### 3. Crea un workflow que ejecute tests e2e

Este pipeline se realizará creando un docker-compose.yaml de todo lo anterior y una vez en el pipeline se haga la build y se levanten los contenedores, el action `cypress-io/github-action@` realizará un escaneo de todo el proyecto y nos dejara un reporte en el pipeline al terminar

docker-compose.yaml
```
version: "3.8"
services:
  hangman-api:
    build:
      context: ./hangman-api
      dockerfile: Dockerfile
    ports:
      - 3001:3000
    networks:
    - e2e
  hangman-front:
    build:
      context: ./hangman-front
      dockerfile: Dockerfile
    environment:
      API_URL: http://localhost:3001
    ports:
      - 8080:8080
    networks:
    - e2e

networks:
  e2e:
```

```
name: CI

on:
  workflow_dispatch:

jobs:
  docker-compose:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Building Containers
        run: docker-compose build
      - name: Starting Containers
        run: docker-compose up -d
      - name: Install Node
        uses: actions/setup-node@v1
        with:
          node-version: 14.x
      - name: Install dependencies
        working-directory: ./hangman-e2e/e2e
        run: |
          npm ci
      - name: Cypress Actions
        uses: cypress-io/github-action@v5
        with:
          working-directory: ./hangman-e2e/e2e
```