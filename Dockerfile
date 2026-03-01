FROM nginx:alpine

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy all static site files
COPY . /usr/share/nginx/html

# Remove deploy-related files from served content
RUN rm -f  /usr/share/nginx/html/deploy.sh \
           /usr/share/nginx/html/deploy.config \
           /usr/share/nginx/html/docker-compose.yml \
           /usr/share/nginx/html/Dockerfile \
           /usr/share/nginx/html/Makefile \
           /usr/share/nginx/html/nginx.conf \
           /usr/share/nginx/html/REQUIREMENTS.md \
           /usr/share/nginx/html/CLAUDE.md

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
