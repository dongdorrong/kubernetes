FROM nginx:alpine

RUN echo "My name is [$DONGDORRONG_VAR] !!" > /usr/share/nginx/html/index.html ; \
    chmod +x run.sh ;\
    apk update && apk upgrade --ignore alpine-baselayout