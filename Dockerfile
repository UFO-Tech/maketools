FROM alpine:latest

RUN apk add --no-cache \
    bash \
    git \
    make \
    docker-cli \
    yq \
    curl \
    coreutils

WORKDIR /ufo-maketools

COPY entrypoint/entrypoint.sh /usr/local/bin/maketools
COPY core/ /ufo-maketools/
COPY VERSION /ufo-maketools/VERSION

RUN chmod +x /usr/local/bin/maketools \
    /ufo-maketools/commands/install.sh \
    /ufo-maketools/commands/update.sh

ENTRYPOINT ["maketools"]