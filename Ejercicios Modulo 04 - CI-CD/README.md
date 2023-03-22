## Jenkins

### 1. CI/CD de una Java + Gradle
```
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                sh '''
                git clone https://github.com/alezanshe/jenkins1.git
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
                sh '''
                git clone https://github.com/alezanshe/jenkins2.git
                cd jenkins2/
                '''
            }
        }
        stage('Compile') {
            steps {
                sh '''
                cd jenkins-resources/calculator/
                ./gradlew compileJava
                '''
            }
        }
        stage('Unit Tests') {
            steps {
                sh '''
                cd jenkins-resources/calculator/
                ./gradlew test
                '''
            }
        }
    }
}
```

## Gitlab

### 1. CI/CD de una aplicación spring
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

## guest
A continuación se presentan algunas de las acciones que un usuario con rol "Guest" puede realizar en GitLab:

Ver el código fuente y los archivos del proyecto.
Ver las solicitudes de extracción y los problemas en el proyecto.
Ver los comentarios en las solicitudes de extracción y los problemas.
Ver el registro de actividad del proyecto.
Ver los archivos de registro de la construcción de CI/CD, pero no pueden modificar la configuración de CI/CD.
Crear solicitudes de extracción en un fork del proyecto, pero no pueden hacerlo directamente en el proyecto original.
Crear problemas en el proyecto.

## reporter
A continuación se presentan algunas de las acciones que un usuario con rol "Reporter" puede realizar en GitLab:

Ver el código fuente y los archivos del proyecto.
Ver las solicitudes de extracción y los problemas en el proyecto.
Ver los comentarios en las solicitudes de extracción y los problemas.
Ver el registro de actividad del proyecto.
Ver los archivos de registro de la construcción de CI/CD, pero no pueden modificar la configuración de CI/CD.
Crear solicitudes de extracción en el proyecto.
Crear problemas en el proyecto.
Comentar en solicitudes de extracción y problemas.
Ver los detalles de la configuración del proyecto y las ramas protegidas.
Ver el contenido de la Wiki del proyecto.
Ver y descargar los artefactos de construcción de CI/CD.

## developer
A continuación se presentan algunas de las acciones que un usuario con rol "Developer" puede realizar en GitLab:

Ver y modificar el código fuente y los archivos del proyecto.
Crear y modificar las solicitudes de extracción en el proyecto.
Crear y cerrar problemas en el proyecto.
Comentar en solicitudes de extracción y problemas.
Ver el registro de actividad del proyecto.
Ver y descargar los artefactos de construcción de CI/CD.
Configurar y ejecutar la construcción de CI/CD para el proyecto.
Acceder a los entornos de producción y de prueba.
Ver y modificar la configuración del proyecto, incluyendo la configuración de CI/CD y las ramas protegidas.

## mantainer
A continuación se presentan algunas de las acciones que un usuario con rol "Maintainer" puede realizar en GitLab:

Ver y modificar el código fuente y los archivos del proyecto.
Crear y modificar las solicitudes de extracción en el proyecto.
Crear y cerrar problemas en el proyecto.
Comentar en solicitudes de extracción y problemas.
Ver y descargar los artefactos de construcción de CI/CD.
Configurar y ejecutar la construcción de CI/CD para el proyecto.
Acceder a los entornos de producción y de prueba.
Ver y modificar la configuración del proyecto, incluyendo la configuración de CI/CD y las ramas protegidas.
Aprobar solicitudes de extracción y fusionarlas con el repositorio.
Crear, modificar y eliminar ramas protegidas.
Invitar, eliminar y modificar los roles de los miembros del proyecto.
Crear, modificar y eliminar etiquetas y lanzamientos.

### 3. Crear un nuevo repositorio, que contenga una pipeline, que clone otro proyecto, springapp anteriormente creado. Realizarlo de las siguientes maneras:
Crear un nuevo repositorio, que contenga una pipeline, que clone otro proyecto, springapp anteriormente creado. Realizarlo de las siguientes maneras:
Con el método de CI job permissions model

¿Qué ocurre si el repo que estoy clonando no estoy cómo miembro?

No se puede clonar porque es privado por defecto

Con el método deploy keys
Crear deploy key en el repo springapp y poner solo lectura
Crear pipeline que usando la deploy key

## GitHub Actions

### 1. Crea un workflow CI para el proyecto de frontend
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
```
name: CI

on: push

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
          npm install
      - name: Running Tests
        working-directory: ./hangman-e2e/e2e
        run: |
          npm run test
      - name: Running Cypress
        working-directory: ./hangman-e2e/e2e
        run: npx cypress run
      - name: Stopping Containers
        run: docker-compose down
```