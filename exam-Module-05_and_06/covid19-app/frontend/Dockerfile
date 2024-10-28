# Dockerfile
FROM node:14
WORKDIR /app

COPY public/ /app/public/
COPY src/ /app/src/
COPY package.json /app/
COPY package-lock.json /app/

RUN npm install
EXPOSE 3000
CMD ["npm", "start"]