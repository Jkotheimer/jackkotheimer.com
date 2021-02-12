FROM nginx
MAINTAINER Jack Kotheimer

ARG ENV

LABEL com.jackkotheimer.version="1.0.0"

EXPOSE 80/tcp
EXPOSE 443/tcp

VOLUME /srv
COPY . /srv

CMD ["/srv/deployment/run.sh", "-g", "daemon off;"]
