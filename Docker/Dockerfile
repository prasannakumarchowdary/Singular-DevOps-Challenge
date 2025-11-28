
FROM nginx:stable-alpine
LABEL maintainer="DevOps Engineer"

RUN rm -rf /usr/share/nginx/html/*
COPY report /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]