FROM openjdk:8-jre
MAINTAINER Maksym Pidlisnyi <maksim@nightbook.info>

ENV ZOOCFGDIR=/conf \
    ZOO_DATA_DIR=/data \
    ZOO_DATA_LOG_DIR=/datalog \
    ZOO_PORT=2181 \
    ZOO_TICK_TIME=2000 \
    ZOO_INIT_LIMIT=5 \
    ZOO_SYNC_LIMIT=2

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests  -y \
	wget \
	gnupg \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

# Add a user and make dirs
RUN set -x \
    && mkdir -p "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOOCFGDIR"

ARG DISTRO_NAME=zookeeper-3.4.13

# Download Apache Zookeeper, verify its PGP signature, untar and clean up
RUN wget -q "http://www.apache.org/dist/zookeeper/$DISTRO_NAME/$DISTRO_NAME.tar.gz" \
    && wget -q "http://www.apache.org/dist/zookeeper/$DISTRO_NAME/$DISTRO_NAME.tar.gz.asc"

COPY KEYS KEYS

RUN set -x \
    && gpg --import KEYS \
    && gpg --batch --verify "$DISTRO_NAME.tar.gz.asc" "$DISTRO_NAME.tar.gz" \
    && tar -xzf "$DISTRO_NAME.tar.gz" \
    && mv "$DISTRO_NAME/conf/"* "$ZOOCFGDIR" \
    && rm -r "$DISTRO_NAME.tar.gz" "$DISTRO_NAME.tar.gz.asc"

COPY log4j.properties "${ZOOCFGDIR}/log4j.properties"
WORKDIR $DISTRO_NAME
VOLUME ["$ZOO_DATA_DIR", "$ZOO_DATA_LOG_DIR"]

EXPOSE $ZOO_PORT 2888 3888

ENV PATH=$PATH:/$DISTRO_NAME/bin

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["zkServer.sh", "start-foreground"]
