FROM nginx:alpine

RUN echo "My name is SERVICE_BB !!" > /usr/share/nginx/html/index.html ; \
    chmod +x run.sh ;\
    apk update && apk upgrade --ignore alpine-baselayout