# Jenkins 1

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

# Jenkins 2

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

# Gitlab 1
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

# Github Actions 1
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
```
# Github Actions 2
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

## Github Actions 3
```
docker build -t hangman-api .
docker build -t hangman-front .
docker build -f cypress-16.dockerfile -t cypress .
docker run -d --rm -p 3001:3000 hangman-api
docker run -d --rm -p 8080:8080 -e API_URL=http://localhost:3001 hangman-front
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