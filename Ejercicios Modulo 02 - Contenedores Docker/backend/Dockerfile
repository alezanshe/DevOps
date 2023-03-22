FROM node:lts-alpine

WORKDIR /src/app

COPY ["package.json", "package-lock.json*", "./"]

RUN npm install

COPY . .

EXPOSE 5000

CMD ["npm", "start"]