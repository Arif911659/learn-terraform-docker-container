# Use the official Nginx image
FROM nginx:alpine

# Copy the Nginx configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/

# Expose the ports for Nginx
EXPOSE 80
