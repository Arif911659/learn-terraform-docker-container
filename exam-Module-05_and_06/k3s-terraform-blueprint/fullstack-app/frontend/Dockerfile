#Set the base image
FROM node:16-alpine as build
#Set the working directory
WORKDIR /app
#Copy the package.json and package-lock.json files
COPY package*.json ./
#Install the dependencies
RUN npm install
#Copy the rest of the application code
COPY . .
#Build the application
RUN npm run build

#Set the base image
FROM nginx:alpine
#Copy the build output from the previous stage
COPY --from=build /app/build /usr/share/nginx/html
#Expose port 80
EXPOSE 80
#Start the Nginx server
CMD ["nginx", "-g", "daemon off;"]