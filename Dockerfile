FROM nginx
MAINTAINER Jack Kotheimer

ARG ENV

LABEL com.jackkotheimer.version="1.0.0"

EXPOSE 80/tcp

VOLUME /srv
COPY . /srv

RUN cp /srv/deployment/$ENV/run.sh /run.sh

CMD ["/run.sh", "-g", "daemon off;"]
